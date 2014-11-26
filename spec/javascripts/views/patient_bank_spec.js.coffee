describe 'PatientBankView', ->

  beforeEach ->
    @measures = bonnie.measures
    @patients = new Thorax.Collections.Patients getJSONFixture('patients.json'), parse: true
    # mockup some shared patients
    @patients.at(0).set('is_shared', true)
    @patients.at(2).set('is_shared', true)
    @bankpatients = @patients.where({'is_shared': true})

    @measure = bonnie.measures.filter( (m) -> return m.get('populations').length > 1 )[0]
    # @currentPopulation = @measure.get('populations').first()

    # @patientBankView = new Thorax.Views.PatientBankView
    @patientBankView = new Thorax.Views.PatientBankView(model: @measure)
    # @patientBankView = new Thorax.Views.PatientBankView(model: @measure, measures: @measures, patients: @patients)
    console.log @patientBankView
    # @patientBankView.collection = @bankpatients
    # manually "sync" with a "server"
    # @patientBankView.differences.add @bankpatients.map (patient) => @currentPopulation.differenceFromExpected(patient)
    @patientBankView.render()
    @patientBankView.appendTo 'body'

  afterEach ->
    # @patientBankView.remove()

  it 'shows list of shared patients', ->
  #   displayed_patients = @patientBankView.$('.shared-patient')
  #   shared_patients = @patients.where({'is_shared': true}).length
  #   expect(displayed_patients.length).toEqual shared_patients

  it 'shows calculation results for each patient', ->
  #   expect(@patientBankView.$('.shared-patient').model().result).toExist()
  #   @patientBankView.$('.shared-patient a[data-toggle="collapse"]').click()
  #   expect(@patientBankView.$('.shared-patient table')).toBeVisible()

  it 'lets users clone patients from the bank to the measure', ->
  #   # cloning the first way
  #   @patientBankView.$('.shared-patient a[data-toggle="collapse"]').click()
  #   expect(@patientBankView.$('[data-call-method="cloneOnePatient"]')).toBeVisible()

  #   console.log @patientBankView.$('input.select-patient')
  #   @patientBankView.$('input.select-patient').prop('checked',true).trigger("change")
  #   # need to manually trigger that
  #   # @patientBankView.changeSelectedPatients()
  #   console.log @patientBankView.$('[data-call-method="cloneBankPatients"]').prop('disabled')
  #   # check if main clone button is enabled
  #   console.log @patientBankView.selectedPatients
  #   # expect(@patientBankView.$('[data-call-method="cloneBankPatients"]').isEnabled()).toBe(true)

  #   # when cloned, sets it to unshared, and adds origin_data attributes
  #   ## indicates that it has been cloned if cloned singly

  # it 'lets users export patients from the bank', ->

  it 'shows measure logic', ->
  #   expect(@patientBankView.$el).toContainText @measure.get('cms_id')
  #   expect(@patientBankView.$('.measure-viz')).toExist()

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
