namespace :bonnie do
  namespace :export do

    desc "Export a representative sample of QRDA patient records for an account"
    task :representative_qrda => :environment do
      user = User.where(email: ENV['EMAIL']).first
      raise "Please provide a valid email address via EMAIL" unless user
      raise "Please provide a name for the output file via ZIPFILE" unless ENV['ZIPFILE']
      # This assumes that the patients are cypress patients, and cross lots of measures; we take 5 patients
      # for each measure that we know at least calculate into the numerator
      calculator = BonnieBackendCalculator.new
      selected_records = Hash.new { |h, k| h[k] = [] }
      user.measures.each do |measure|
        calculator.set_measure_and_population(measure, 0)
        user.records.each do |record|
          break if selected_records[measure].size >= 5
          next unless record.measure_ids.include?(measure.hqmf_set_id)
          result = calculator.calculate(record)
          selected_records[measure] << record if result['NUMER'] != 0
        end
      end
      # Now we have patients for each measure, export them
      qrda_exporter = HealthDataStandards::Export::Cat1.new
      Zip::ZipFile.open(ENV['ZIPFILE'], Zip::ZipFile::CREATE) do |zip|
        selected_records.each do |measure, records|
          start_time = Time.new(Time.zone.at(APP_CONFIG['measure_period_start']).year, 1, 1)
          end_time = Time.new(Time.zone.at(APP_CONFIG['measure_period_start']).year, 12, 31)
          records.each do |record|
            begin
              qrda = qrda_exporter.export(record, [measure], start_time, end_time)
              filename = "#{measure.cms_id}_#{record.last}_#{record.first}.xml"
              puts "Writing #{filename}"
              zip.get_output_stream(filename) { |f| f.puts qrda }
            rescue HealthDataStandards::Export::PatientExportDataCriteriaException => e
              puts "Encountered exception #{e.class}, skipping"
            end
          end
        end
      end
    end

  end
end
