class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:

    'change select[name=patients-filter]': 'moreInput'

    collection:
      sync: ->
        # TODO set expectations only if the patient was originally developed for this measure
        @differences.reset @collection.map (patient) => @currentPopulation.differenceFromExpected(patient)

    rendered: ->
      @$('#sharedResults').on 'shown.bs.collapse hidden.bs.collapse', (e) =>
        @bankLogicView.clearRationale()
        if e.type is 'shown'
          @toggledPatient = $(e.target).model().result
          @bankLogicView.showRationale(@toggledPatient)
        else
          @toggledPatient = null

      @$('#sharedResults').on 'show.bs.collapse hidden.bs.collapse', (e) =>
        $(e.target).parent('.panel').find('.panel-chevron').toggleClass 'fa-angle-right fa-angle-down'

      @$('.patients-filter-input').hide()

      @$('select[name=patients-filter]').selectBoxIt 
        downArrowIcon: "bank-dropdown-arrow", 
        defaultText: "calculates for...", 
        autoWidth: false, 
        theme:
          button: "bank-dropdown-button"
          list: "bank-dropdown-list"
          container: "bank-dropdown-container"
          focus: "bank-dropdown-focus"

  initialize: ->
    @collection = new Thorax.Collections.Patients
    @differences = new Thorax.Collections.Differences()

    populations = @model.get('populations')
    @currentPopulation = populations.first()
    populationLogicView = new Thorax.Views.PopulationLogic(model: @currentPopulation)
    if populations.length > 1
      @bankLogicView = new Thorax.Views.PopulationsLogic collection: populations
      @bankLogicView.setView populationLogicView
    else
      @bankLogicView = populationLogicView

  measureSelectionContext: (measure) ->
    _(measure.toJSON()).extend isSelected: measure is @model

  differenceContext: (difference) ->
    _(difference.toJSON()).extend
      patient: difference.result.patient.toJSON()
      measure_id: @model.get('hqmf_set_id')
      cms_id: @model.get('cms_id')
      episode_of_care: @model.get('episode_of_care')

  moreInput: (e) ->
    selected = @$(e.currentTarget).val()
    @$('.patients-filter-input').find('input').hide()
    if selected is "measure"
      @$('.patients-filter-input').show("slow").find('input[name="origin_measure"]').show()
    else if selected is "user"
      @$('.patients-filter-input').show("slow").find('input[name="origin_email"]').show()
    else 
      @$('.patients-filter-input').hide("slow")


