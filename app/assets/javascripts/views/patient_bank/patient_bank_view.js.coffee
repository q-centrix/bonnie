class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'click .bank-dropdown-button': 'adjustDropdowns'
    collection:
      sync: ->
        @differences.reset @collection.map (patient) => @currentPopulation.differenceFromExpected(patient)

    rendered: ->
      # TODO do we also need to @trigger 'rationale:clear' and set toggledPatient?
      @$('#sharedResults').on 'show.bs.collapse hidden.bs.collapse', (e) ->
        $(e.target).parent('.panel').find('.panel-chevron').toggleClass 'fa-angle-right fa-angle-down'

      @$('select[name=patients-filter]').selectBoxIt downArrowIcon: "bank-dropdown-arrow", defaultText: "calculates for...", aggressiveChange: true, autoWidth: false, theme:
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

  adjustDropdowns: (e) ->
    $dropdown = $(e.currentTarget)
    listWidth = $dropdown.closest('.selectboxit-container').width() - $dropdown.find('.selectboxit-arrow-container').width()
    $dropdown.next('.bank-dropdown-list').attr "style", (i,s) -> s + "min-width: #{listWidth}px !important;"
