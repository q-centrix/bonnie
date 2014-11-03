class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'change select[name=patients-filter]':  'supplyExtraFilterInput'
    'submit form':                          'addFilter'
    'change input.select-patient':          'changeSelectedPatients'

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
          @updateDisplayedCoverage()

      @$('#sharedResults').on 'show.bs.collapse hidden.bs.collapse', (e) =>
        $(e.target).prev('.panel-heading').toggleClass('opened-patient')
        $(e.target).parent('.panel').find('.panel-chevron').toggleClass 'fa-angle-right fa-angle-down'

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
    @differences = new Thorax.Collections.Differences

    @selectedPatients = new Thorax.Collection
    @selectedPatients.on 'add remove', _.bind(@updateDisplayedCoverage, this)

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
    @availableFilters.add filter: Thorax.Models.MeasureAuthorFilter, name: 'created by...'
    @availableFilters.add filter: Thorax.Models.MeasureFilter, name: 'from measure...'

  changeSelectedPatients: (e) ->
    patient = $(e.target).model().result.patient # gets the patient model
    if $(e.target).is(':checked')
      @selectedPatients.add patient
    else 
      @selectedPatients.remove patient

  updateDisplayedCoverage: ->
    if !@$('.shared-patient > .in').length # only show coverage if no patients are expanded
      if @selectedPatients.isEmpty() 
        @bankLogicView.showCoverage()
      else 
        @bankLogicView.clearCoverage() # TODO coverage tailored to selected patients

  measureSelectionContext: (measure) ->
    _(measure.toJSON()).extend isSelected: measure is @model

  appliedFilterContext: (filter) ->
    _(filter.toJSON()).extend
      label: filter.label()

  differenceContext: (difference) ->
    _(difference.toJSON()).extend
      patient: difference.result.patient.toJSON()
      measure_id: @model.get('hqmf_set_id')
      cms_id: @model.get('cms_id')
      episode_of_care: @model.get('episode_of_care')

  patientFilter: (difference) ->
    patient = difference.result.patient
    @appliedFilters.all (filter) -> filter.apply(patient)

  addFilter: (e) ->
    e.preventDefault()
    $form = $(e.target)
    $select = $form.find('select')
    $additionalRequirements = $form.find('input[name=additional_requirements]')
    filterModel = $select.find(':selected').model().get('filter')
    if filterModel.name is "PopulationsFilter" 
      filter = new filterModel($select.val(),@currentPopulation)
    else
      filter = new filterModel($additionalRequirements.val()) # TODO validate input
    @appliedFilters.add(filter)
    @updateFilter()
    # TODO - don't keed adding endless filters or duplicate filters
    @$('input[name="additional_requirements"]').remove()
    $select.find('option:eq(0)').prop("selected", true) # reset option viewed
    $select.data("selectBox-selectBoxIt").refresh() # update dropdown

  removeFilter: (e) ->
    thisFilter = $(e.target).model()
    @appliedFilters.remove(thisFilter)
    @updateFilter()

  supplyExtraFilterInput: (e) ->
    $select = $(e.target)
    # the filter is associated with the option, not the select - we need to get the selected option upon a select event
    filterModel = $select.find(':selected').model().get('filter')
    additionalRequirements = filterModel::additionalRequirements
    # remove any filter added previously
    @$('input[name="additional_requirements"]').remove()
    if additionalRequirements?
      # FIXME use a partial, this is a lot of markup
      input = "<input type='#{additionalRequirements.type}' class='form-control' name='additional_requirements' placeholder='#{additionalRequirements.text}'>"
      div = @$('.additional-requirements')
      $(input).hide().appendTo(div).animate({width: 'toggle'},"fast")

  cloneBankPatients: ->
    # TODO do something else if there are no selected patients

    this_measure_id = @model.get('hqmf_set_id')
    this_cms_id = @model.get('cms_id')
    this_user_id = @model.get('user_id')

    @selectedPatients.each (patient) ->
      clonedPatient = patient.deepClone(omit_id: true)
      # set clone to this measure, user, and default to unshared
      patient_measures = clonedPatient.get('measure_ids')
      patient_measures[0] = this_measure_id
      clonedPatient.set
        'measure_ids': patient_measures,
        'user_id': this_user_id,
        'is_shared': false,
        'origin_cms_id': this_cms_id
        # todo add origin_email

      # clonedPatient.save clonedPatient.toJSON(),
      #   success: (patientModel) =>
      #     @patients.add patientModel # make sure that the patient exist in the global patient collection
      #     @model.get('patients').add patientModel # and that measure's patient collection
      #     if bonnie.isPortfolio
      #     @measures.each (m) -> m.get('patients').add model
      #     route = if @measure then "measures/#{@measure.get('hqmf_set_id')}" else "patients"
      #     bonnie.navigate route, trigger: true

