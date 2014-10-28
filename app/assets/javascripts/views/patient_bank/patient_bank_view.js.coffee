class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'change select[name=patients-filter]': 'supplyExtraFilterInput'

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

      # FIXME add selectBoxIt back in when it doesn't interfere with events
      # @$('select[name=patients-filter]').selectBoxIt 
      #   downArrowIcon: "bank-dropdown-arrow", 
      #   defaultText: "calculates for...", 
      #   autoWidth: false, 
      #   theme:
      #     button: "bank-dropdown-button"
      #     list: "bank-dropdown-list"
      #     container: "bank-dropdown-container"
      #     focus: "bank-dropdown-focus"

  initialize: ->
    @collection = new Thorax.Collections.Patients
    @differences = new Thorax.Collections.Differences

    populations = @model.get('populations')
    @currentPopulation = populations.first()
    populationLogicView = new Thorax.Views.PopulationLogic(model: @currentPopulation)
    if populations.length > 1
      @bankLogicView = new Thorax.Views.PopulationsLogic collection: populations
      @bankLogicView.setView populationLogicView
    else
      @bankLogicView = populationLogicView

    @appliedFilters = new Thorax.Collection
    @availableFilters = new Thorax.Collection

    _(@currentPopulation.populationCriteria()).each (criteria) =>
      @availableFilters.add filter: Thorax.Models.PopulationsFilter, name: criteria
    @availableFilters.add filter:Thorax.Models.MeasureAuthorFilter, name: 'created by...'

  measureSelectionContext: (measure) ->
    _(measure.toJSON()).extend isSelected: measure is @model

  differenceContext: (difference) ->
    _(difference.toJSON()).extend
      patient: difference.result.patient.toJSON()
      measure_id: @model.get('hqmf_set_id')
      cms_id: @model.get('cms_id')
      episode_of_care: @model.get('episode_of_care')

  supplyExtraFilterInput: (e) ->
    $select = $(e.target)
    # the filter is associated with the option, not the select - we need to get the selected option upon a select event
    filterModel = $select.find(':selected').model().get('filter')
    additionalRequirements = filterModel::additionalRequirements
    # remove any filter added previously
    $select.next('.additional-requirements').remove()
    if additionalRequirements?
      # FIXME use a partial, this is a lot of markup
      $select.after "<div class='form-group additional-requirements'><input type='text' name='additional_requirements' class='form-control' placeholder='#{additionalRequirements.text}'></div>"
