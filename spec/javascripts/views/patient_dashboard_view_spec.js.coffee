describe 'EmptyPatientDashboardView', ->

  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS128v5')
    @measureLayout = new Thorax.Views.MeasureLayout(measure: @measure)
    # PatientDashboardView is set as view in showDashboard
    @measureLayout.showDashboard(showFixedColumns: true)

  afterEach ->
    @measureLayout.remove()

  it 'renders dashboard', ->
    expect(@measureLayout.$el).toContainText @measure.get('cms_id')
    expect(@measureLayout.$el.html()).toContain "patient-dashboard"
    
  it 'contains empty table when no patients loaded', ->
    dataTable = @measureLayout.$('#patientDashboardTable').DataTable()
    expect(dataTable.rows().count()).toEqual 0
    
  it 'view displays the correct number of populations', ->
    num_populations = @measure.get('populations').length
    console.log(num_populations)
    expect(@measureLayout.populations.length).toEqual num_populations

describe 'PopulatedPatientDashboardView', ->

  beforeEach (done) ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS128v5')
    collection = new Thorax.Collections.Patients getJSONFixture('patients.json'), parse: true
    @patients = collection.filter((patient) => 
      @measure.get('hqmf_set_id') in patient.get('measure_ids'))
    # need to add patients to the measure
    @measure.get('patients').add(@patients)
    @measureLayout = new Thorax.Views.MeasureLayout(measure: @measure, patients: @patients)
    
    # PatientDashboardView is set as view in showDashboard
    @measureLayout.showDashboard(showFixedColumns: true)
    @patientDashboardLayout = @measureLayout.getView() # multiple populations so have a layout view
  
    @patientDashboardLayout.viewSet.done =>
      @patientDashboardView = @patientDashboardLayout._view
      @patientDashboardView.patientsLoaded.done =>
        done()

  afterEach ->
    @patientDashboardView.results.reset() # empties the results so that they get recalculated for each run
    @patientDashboardView.unbind()
    @patientDashboardView.remove()

  # Ideally,this number would be pulled from the number of rows in datatable
  it 'view has correct number of patients', ->
    console.log this.patients.length
    expect(@patientDashboardView.patientData.length).toEqual this.patients.length
    dataTable = @patientDashboardView.$('#patientDashboardTable').DataTable()
    dataTable.on "all", (eventName) =>
      console.log eventName
    expect(dataTable.rows().count()).toEqual 19


  it 'fake test 2', ->
    expect(true).toEqual(true)
