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
    
    @patientDashboardLayout = @measureLayout._view # multiple populations so have a layout view
    @patientDashboardLayout.viewSet.done =>
      @patientDashboardView = @patientDashboardLayout._view
      @patientDashboardView.patientsLoaded.done =>
        done()

  afterEach ->
    @measureLayout.remove()
    @patientDashboardView.results.reset() # empties the results so that they get recalculated for each run

  it 'fake test 1', ->
    expect(true).toEqual(true)

  it 'fake test 2', ->
    expect(true).toEqual(true)
