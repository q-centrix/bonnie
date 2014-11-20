describe 'PatientBankView', ->

  beforeEach ->
    @measures = bonnie.measures
    @patients = bonnie.patients
    # @patients = new Thorax.Collections.Patients getJSONFixture('patients.json'), parse: true
    @measure = bonnie.measures.first()
    # @patientBankView = new Thorax.Views.PatientBankView(model: @measure, measures: @measures, patients: @patients)
    # @patientBankView.render()
    # @$el = @patientBankView.$el
    # @patientBankView.appendTo 'body'

  # afterEach ->
    # @patientBankView.remove()

  it 'shows list of shared patients', ->
    shared_patients = bonnie.patients.where({ is_shared: true })
    displayed_patients = @patientBankView.$('.shared-patient')
    expect(displayed_patients.length).toEqual shared_patients.length
    expect($('.shared-patient').model().result.patient.get('cms_id')).toBeTruthy()
    expect($('.shared-patient').model().result.patient.get('user_email')).toBeTruthy()

  it 'shows calculation results for each patient', ->
    expect(@patientBankView.$('.shared-patient').model().result).toExist()
    expect(@patientBankView.$('.shared-patient').model().get('done')).toBeTruthy()
    @patientBankView.$('.patient-btn').click()
    expect(@patientBankView.$('.table')).toBeVisible()

  it 'lets users clone patients from the bank to the measure', ->
    @patientBankView.$('.patient-btn').click()
    expect(@patientBankView.$('[data-call-method="cloneOnePatient"]')).toBeVisible()


    @patientBankView.$('input.select-patient').prop('checked','true')
    # check if main clone button is enabled

    # when cloned, sets it to unshared, and adds origin_data attributes
    ## indicates that it has been cloned if cloned singly

  # it 'lets users export patients from the bank', ->

  it 'shows measure logic', ->
    # expect(@patientBankView.$el).toContainText @measure.get('cms_id')
    # expect(@patientBankView.$('.measure-viz')).toExist()

  describe 'toggles measure coverage and rationale', ->

    it 'shows measure coverage for all bank patients', ->
      # when no patients expanded
      # and when no patients selected
      # check for multiple stratifications/populations?

    it 'shows measure coverage for selected patients', ->
      # when no patients expanded
      # when patients are selected
      # check for multiple stratifications/populations?

    it 'toggles logic rationale for expanded patient', ->
      # when patient expanded
      # check for multiple stratifications/populations?

  describe 'lets user filter the patient list', ->

    it 'filters by user who shared patient', ->
      # user email matches

    it 'filters by measure of shared patient', ->
      # CMS ID

    it 'filters by relevant population on this measure', ->
      # measure populations
      # check for multiple stratifications/populations?
