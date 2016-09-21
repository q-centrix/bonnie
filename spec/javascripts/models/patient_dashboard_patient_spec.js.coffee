describe 'PatientDashboardPatient', ->
  
  beforeEach (done) ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS128v5')
    
    # getting a particular patient whose characteristics we know about.
    # patient: Hillary Clinton
    #  DOB: 4/05/1927
    #  Diagnosis: Major Depression 01/01/2012
    #  Medication, Dispensed: Antidepressant Medication 01/15/2012-01/15/2012
    #  Medication, Active: Antidepressant Medication 05/08/2012 - 05/08/2012
    #  Encounter, Performed: Annual Wellness Visit 12/31/2012 - 12/31/2012
    collection = new Thorax.Collections.Patients getJSONFixture('patients.json'), parse: true
    @patient = collection.filter((patient) => 
      @measure.get('hqmf_set_id') in patient.get('measure_ids') && patient.get('first') == "Hillary")[0]
    
    # getting the population sets relevant to the model (IPP, DENOM, etc.)
    codes = (population['code'] for population in @measure.get('measure_logic'))
    @populationSets = _.intersection(Thorax.Models.Measure.allPopulationCodes, codes)
    
    @population = @measure.get('populations').at(0)
    
    @patientDashboard = new Thorax.Models.PatientDashboard @measure, @populationSets, @population
    
    # retrieving the calculation result for the patients relevant to the measure.
    # this is a deferred operation. We create the @patientDashboardPatient once this completes.
    @results = @population.calculateResult(@patient)
    @results.calculationsComplete =>
      console.log("in caculationsComplete")
      # there is only one result because we calculated for just a single patient
      # need to get the JSON representation because this adds additional information to the model
      # (and it's what the code expects).
      @result = @results.at(0).toJSON()
      @patientDashboardPatient = new Thorax.Models.PatientDashboardPatient(@patient, @patientDashboard, @measure, @result, @populationSets, @population)
      done()
    
  it 'has a basic test', ->
    console.log("got to test")
    expect(true).toEqual(true)
