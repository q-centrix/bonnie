describe 'MeasureView', ->

  beforeEach ->
    @measure = bonnie.measures.filter( (m) -> return m.get('populations').length > 1 )[0]
    @patient = new Thorax.Models.Patient getJSONFixture('patients.json')[0], parse: true
    @measure.get('patients').add @patient
    @measureView = new Thorax.Views.Measure(model: @measure, patients: @measure.get('patients'))
    @measureView.render()
    @measureView.appendTo 'body'

  afterEach ->
    @measureView.remove()

  it 'renders measure details', ->
    expect(@measureView.$el).toContainText @measure.get('title')
    expect(@measureView.$el).toContainText @measure.get('cms_id')
    expect(@measureView.$el).toContainText @measure.get('description')

  it 'renders measure populations', ->
    expect(@measureView.$('[data-toggle="tab"]')).toExist()
    expect(@measureView.$('.rationale-target')).toBeVisible()
    expect(@measureView.$('[data-toggle="collapse"]')).not.toHaveClass('collapsed')
    @measureView.$('[data-toggle="collapse"]').click()
    expect(@measureView.$('[data-toggle="collapse"]')).toHaveClass('collapsed')
    @measureView.$('[data-toggle="tab"]').last().click()
    expect(@measureView.$('[data-toggle="collapse"]')).not.toHaveClass('collapsed')

  it 'renders patient results', ->
    expect(@measureView.$('.patient')).toExist()
    expect(@measureView.$('.toggle-result')).not.toBeVisible()
    expect(@measureView.$('.btn-show-coverage')).not.toBeVisible()
    @measureView.$('[data-call-method="expandResult"]').click()
    expect(@measureView.$('.toggle-result')).toBeVisible()
    expect(@measureView.$('.btn-show-coverage')).toBeVisible()

  it 'lets users share or unshare a patient', ->
    @measureView.$('[data-call-method="expandResult"]').click()
    expect(@measureView.$('.share-patient')).toBeVisible()
    testpatient = @measureView.$('[data-call-method="togglePatient"]')
    unclicked = testpatient.model().result.patient.get('is_shared')
    testpatient[0].click()
    clicked = testpatient.model().result.patient.get('is_shared')
    expect(clicked).not.toEqual(unclicked)
    expect(clicked).toBeTruthy()

  it 'lets users navigate to the patient bank', ->
    @measureView.$('[data-call-method="patientSettings"]').click()
    expect(@measureView.$('.import-patients')).toBeVisible()
