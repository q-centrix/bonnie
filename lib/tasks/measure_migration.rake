namespace :bonnie do
  namespace :measures do

    desc "Delete Value Set indexes that are not needed in Bonnie"
    task :delete_unnecessary_value_set_indexes => :environment do
      HealthDataStandards::SVS::ValueSet.collection.indexes.drop({"concepts.code"=>1})
      HealthDataStandards::SVS::ValueSet.collection.indexes.drop({"concepts.code_system"=>1})
      HealthDataStandards::SVS::ValueSet.collection.indexes.drop({"concepts.code_system_name"=>1})
      HealthDataStandards::SVS::ValueSet.collection.indexes.drop({"concepts.display_name"=>1})
    end

    desc "Delete unused value sets"
    task :delete_unused_value_sets => :environment do
      all_value_set_ids = HealthDataStandards::SVS::ValueSet.only(:id).map(&:id)
      used_value_set_ids = []
      Measure.each do |m|
        used_value_set_ids.concat(m.value_sets.only(:id).map(&:id))
      end
      raise "No used value sets, something must be wrong" unless used_value_set_ids.size > 0
      used_value_set_ids.uniq!
      unused_value_set_ids = (all_value_set_ids - used_value_set_ids)
      puts "Deleting #{unused_value_set_ids.size} unused value sets"
      HealthDataStandards::SVS::ValueSet.where(:_id.in => unused_value_set_ids).delete_all
    end

    desc "Consolidate the value sets to unique entities and move away from user versioning"
    task :consolidate_value_sets => :environment do

      user_oid_to_version = Hash.new
      seen_hashes = Set.new
      to_delete = []
      to_save = []
      size = HealthDataStandards::SVS::ValueSet.count()
      progress = 0

      start_time = Time.now
      puts "Looking for duplicate Value Sets"

      HealthDataStandards::SVS::ValueSet.each do |vs|
        progress += 1
        if (progress % 500 == 0)
          puts "\n#{progress} / #{size}"
        end

        vs.generate_bonnie_hash
        user_oid_to_version[[vs.oid, vs.user_id]] = vs.bonnie_hash

        if (seen_hashes.add?(vs.bonnie_hash))
          to_save.push(vs)
          print "."
        else
          to_delete.push(vs)
          print "!"
        end
        $stdout.flush()

      end

      puts "\nFinished looking for duplicate Value Sets (elapsed time: #{Time.now - start_time})"

      start_time = Time.now
      puts "Updating measures with new value set versions"

      size = Measure.count()
      progress = 0

      Measure.each do |m|
        progress += 1
        if (progress % 500 == 0)
          puts "#{progress} / #{size}"
        end

        m.oid_to_version = []
        m.value_set_oids.each do |oid|
          m.oid_to_version.push(user_oid_to_version[[oid, m.user_id]])
        end
        m.save!
      end

      puts "\nFinished updating measures with new value set versions (elapsed time: #{Time.now - start_time})"

      start_time = Time.now
      puts "Deleting #{to_delete.size} duplicate value sets"

      HealthDataStandards::SVS::ValueSet.where(:_id.in => to_delete.map(&:id)).delete_all

      puts "\nFinished deleting duplicate value sets (elapsed time: #{Time.now - start_time})"

      start_time = Time.now
      puts "Saving value sets with hash information"

      size = to_save.count()
      progress = 0

      to_save.each do |vs|
        progress += 1
        if (progress % 500 == 0)
          puts "#{progress} / #{size}"
        end
        vs.save!
      end

      puts "\nFinished saving value sets with hash information (elapsed time: #{Time.now - start_time})"

    end

    desc "Migrates measures and value_sets away from User versioning"
    task :apply_hash => :environment do
      
      user_oid_to_version = Hash.new
      seen_hashes = Set.new
      to_delete = []
      to_save = []
      size = HealthDataStandards::SVS::ValueSet.count()
      progress = 0

      HealthDataStandards::SVS::ValueSet.each do |vs|
        progress += 1
        if (progress % 500 == 0)
          puts "\n#{progress} / #{size}"
        end
        
        vs.bonnie_hash = HealthDataStandards::SVS::ValueSet.gen_bonnie_hash(vs)
        user_oid_to_version[[vs.oid, vs.user_id]] = vs.bonnie_hash
        
        if (seen_hashes.add?(vs.bonnie_hash).nil?)
          to_delete.push(vs)
          print "!"
        else
          to_save.push(vs)
          print "."
        end
        $stdout.flush()
      end
      
      size = Measure.count()      
      progress = 0

      Measure.each do |m|
        progress += 1
        if (progress % 500 == 0)
          puts "#{progress} / #{size}"
        end
        
        m.oid_to_version = []
        m.value_set_oids.each do |oid|
          m.oid_to_version.push(user_oid_to_version[[oid, m.user_id]])
        end
        m.save!
      end

      size = to_delete.count()      
      progress = 0
      
      to_delete.each do |vs|
        progress += 1
        if (progress % 500 == 0)
          puts "#{progress} / #{size}"
        end
        vs.delete
      end

      size = to_save.count()      
      progress = 0
      
      to_save.each do |vs|
        progress += 1
        if (progress % 500 == 0)
          puts "#{progress} / #{size}"
        end
        vs.save!
      end
    end

    desc "Updates versions on value sets"
    task :enrich_vs_versions => :environment do
      api = HealthDataStandards::Util::VSApiV2.new("https://vsac.nlm.nih.gov/vsac/ws/Ticket", "https://vsac.nlm.nih.gov/vsac/svs/RetrieveValueSet", "https://vsac.nlm.nih.gov/vsac/oid", "", "") #need to get this to run with config
      to_save = []
      size = HealthDataStandards::SVS::ValueSet.count()
      progress = 0
      oid_version_to_content = Hash.new
      to_proc = []

      HealthDataStandards::SVS::ValueSet.each do |vs|
        to_proc.push(vs)
      end

      to_proc.each do |vs|
        unversioned_hash = HealthDataStandards::SVS::ValueSet.gen_versionless_hash(vs)
        
        progress += 1
        if (progress % 50 == 0)
          puts "\n#{progress} / #{size}"
        end
        if (vs.version != "draft")
          version_doc = Nokogiri::XML(api.get_versions(vs.oid))

          version_doc.xpath("//version").each do |node|
            begin
              to_check = nil
              retrieved_value = api.get_valueset(vs.oid, {version: node.content})
              retrieved_doc = Nokogiri::XML(retrieved_value)
              to_check = HealthDataStandards::SVS::ValueSet.load_from_xml(retrieved_doc)
              to_check_hash = HealthDataStandards::SVS::ValueSet.gen_versionless_hash(to_check)

              if (to_check_hash == unversioned_hash)
                vs.version = node.content
                vs.bonnie_hash = nil
                vs.bonnie_hash = HealthDataStandards::SVS::ValueSet.gen_bonnie_hash(vs)
                to_save.push(vs)
                break
              end
            rescue Exception => e
              puts e.message
              puts "Ya broke it!"
            end
          end
        end
      end
      to_save.each do |vs|
        vs.save!
      end
      
    end

    task :check_sets => :environment do
      HealthDataStandards::SVS::ValueSet.each do |vs|
        puts vs.bonnie_hash
      end
      
      Measure.each do |m|
        puts m.oid_to_version
      end
    end
  end
end
