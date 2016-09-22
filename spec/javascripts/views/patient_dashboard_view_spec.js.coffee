describe 'PatientDashboardView', ->

  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS156v2')
    @patients = new Thorax.Collections.Patients getJSONFixture('patients.json')
    debugger
    @patientDashboard = new Thorax.Views.MeasureLayout(measure: @measure, patients: @patients)
    # PatientDashboardView is set as view in showDashboard
    @patientDashboard.showDashboard( showFixedColumns: true)

  afterEach ->
    @patientDashboard.remove()

  it 'renders dashboard', ->
    debugger
    expect(@patientDashboard.$el).toContainText @measure.get('cms_id')
    expect(@patientDashboard.$el.html()).toContain "patient-dashboard"
    
  it 'contains empty table when no patients loaded', ->
    dataTable = @patientDashboard.$('#patientDashboardTable').DataTable()
    expect(dataTable.rows().count()).toEqual 0

  
    
  
