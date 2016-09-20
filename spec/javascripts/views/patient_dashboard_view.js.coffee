describe 'PatientDashboardView', ->

  beforeEach ->
    @measure = bonnie.measures.findWhere(cms_id: 'CMS156v2')
    @patients = new Thorax.Collections.Patients getJSONFixture('patients.json')
    @patientDashboard = new Thorax.Views.MeasureLayout(measure: @measure, patients: @patients)
    # PatientDashboardView is set as view in showDashboard
    @patientDashboard.showDashboard( showFixedColumns: false)

  afterEach ->
    @patientDashboard.remove()

  it 'renders dashboard', ->
    expect(@patientDashboard.$el).toContainText @measure.get('cms_id')
    expect(@patientDashboard.$el.html()).toContain "patient-dashboard"
    
  
