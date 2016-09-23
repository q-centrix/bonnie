describe 'EmptyPatientDashboardView', ->

  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS156v2')
    @patientDashboard = new Thorax.Views.MeasureLayout(measure: @measure)
    # PatientDashboardView is set as view in showDashboard
    @patientDashboard.showDashboard( showFixedColumns: true)

  afterEach ->
    @patientDashboard.remove()

  it 'renders dashboard', ->
    expect(@patientDashboard.$el).toContainText @measure.get('cms_id')
    expect(@patientDashboard.$el.html()).toContain "patient-dashboard"
    
  it 'contains empty table when no patients loaded', ->
    dataTable = @patientDashboard.$('#patientDashboardTable').DataTable()
    expect(dataTable.rows().count()).toEqual 0



describe 'PopulatedPatientDashboardView', ->

  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS156v2')
    collection = new Thorax.Collections.Patients getJSONFixture('patients.json'), parse: true
    @patient = collection.filter((patient) => 
      @measure.get('hqmf_set_id') in patient.get('measure_ids'))
    
    @patientDashboard = new Thorax.Views.MeasureLayout(measure: @measure, patients: @patient)
    # PatientDashboardView is set as view in showDashboard
    @patientDashboard.on "any", ->
      debugger
    @patientDashboard.showDashboard( showFixedColumns: true)
    @dataTable = @patientDashboard.$('#patientDashboardTable').DataTable()

  afterEach ->
    @patientDashboard.remove()

  it 'contains populated table when patients loaded', ->
    expect(@dataTable.rows().count()).toEqual 0
    
  
