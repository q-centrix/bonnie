describe 'MeasureView', ->

  beforeEach ->
    @measure = bonnie.measures.first()
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
    expect(@measureView.$('.share-patient')).toExist()
    # the button actually shares by changing the patient's is_shared attribute
    # @measureView.$('[data-call-method="togglePatient"]').click()
    @measureView.$('[data-call-method="expandResult"]').click()
    expect(@measureView.$('.share-patient')).toBeVisible()
    @measureView.$('.share-patient').click()
    # expect(@measureView.$('[data-call-method="togglePatient"]').model()).not.toBeUndefined()
    # @measureView.$('[data-call-method="togglePatient"]').first().click()
    # expect($('[data-call-method="togglePatient"]').first().model().result.patient.get('is_shared')).toEqual false
    # the button also unshares

    # the button accurately reflects shared or unshared state

  it 'lets users navigate to the patient bank', ->
    @measureView.$('[data-call-method="patientSettings"]').click()
    expect(@measureView.$('.import-patients')).toBeVisible()
