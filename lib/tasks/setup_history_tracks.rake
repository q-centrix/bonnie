namespace :bonnie do
  namespace :setup_history_tracks do

    # To set up bonnie with measure history:
    # STRONG recommendation: run with 'tee' so that any error messages are captured
    # in an file.
    # 1. Run the db script in db/convert_hqmf_version_number_to_string.js
    #    See instructions in the script.
    # 2. Run sync_expected_values
    #   e.g. bundle exec rake bonnie:setup_history_tracks:sync_expected_values | tee sync_expected_values.log
    # 3. Run store_calculation_results
    #   e.g. bundle exec rake bonnie:setup_history_tracks:store_calculation_results | tee store_calculation_results.log
    #
    # If you are running store_calculation_results multiple times, you need to run.
    # clear_calculation_results before each subsequent run of store_calculation_results:
    #   bundle exec rake bonnie:setup_history_tracks:clear_calculation_results

    desc 'Calculate every patient in the database and stores their calculation results'
    task :store_calculation_results => :environment do
      STDOUT.sync = true

      calculator = BonnieBackendCalculator.new
      puts "There are #{Measure.count} measures to process."
      Measure.no_timeout.each_with_index do |measure, measure_index|
        if measure_index % 100 == 0
          puts measure_index
        else
          print "."
        end

        patients = Record.where(user_id: measure.user_id, measure_ids: measure.hqmf_set_id)
        # Move on if there are no patients associated with this measure for this user
        if patients.count == 0
          next
        end
        measure.populations.each_with_index do |population_set, population_index|
          begin
            calculator.set_measure_and_population(measure, population_index, clear_db_cache: true, rationale: true)
          rescue => e
            puts "\nError for #{measure.user.email if measure.user?} measure #{measure.cms_id} population set #{population_index}:"
            puts "Calculator setup exception: #{e.message}."
            next
          end
          processed_patients_array = []
          patients.no_timeout.each_with_index do |patient, patient_index|

            # For some reason, patients show up multiple times during this iteration.
            # This checks for that and skips those patients to reduce the number of calculations.
            if processed_patients_array.include?(patient)
              next
            end
            processed_patients_array << patient

            begin
              patient.update_calc_results!(measure, population_index, calculator)
            rescue => e
              puts "\nError for #{measure.user.email if measure.user?} measure #{measure.cms_id} population set #{population_index} patient '#{patient.first} #{patient.last}' (_id: ObjectId('#{patient.id}')):"
              puts "Calculation exception: #{e.message}."
              next # Move onto the next patient
            end
          end
        end
      end # measures
      puts
    end # calculate_all

    desc 'Clear the calculation results.'
    task :clear_calculation_results => :environment do
      STDOUT.sync = true
      puts "There are #{Record.count} patients to process"
      Record.no_timeout.each_with_index do |patient, patient_index|
        patient.calc_results = []
        patient.condensed_calc_results = []
        patient.has_measure_history = false
        patient.results_exceed_storage = false
        patient.results_size = 0
        patient.save!
        if patient_index % 100 == 0
          puts patient_index
        else
          print "."
        end
      end
      puts
    end

    desc 'Align expected values on patients with the populations defined on the measure.'
    task :sync_expected_values => :environment do
      STDOUT.sync = true
      puts 'Align expected values on patients with the populations defined on the measure.'
      puts "There are #{Measure.count} measures to process."
      Measure.no_timeout.each_with_index do |measure, measure_index|
        if measure_index % 100 == 0
          puts measure_index
        else
          print "."
        end

        patients = Record.where(user_id: measure.user_id, measure_ids: measure.hqmf_set_id)
        next if patients.count == 0

        patients.no_timeout.each do |patient|
          patient.update_expected_value_structure!(measure)
        end # patients
      end # measures
      puts
    end # task

  end
end
