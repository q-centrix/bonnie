class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'change select[name=patients-filter]':  'supplyExtraFilterInput'
    'submit form':                          'addFilter'
    'change input.select-patient':          'changeSelectedPatients'
    'click .clear-selected':                (e) -> @$('input.select-patient:checked').prop('checked',false).trigger("change")

    collection:
      sync: ->
        @differences.reset @collection.map (patient) => @currentPopulation.differenceFromExpected(patient)
        @differences.each (d) =>
          # find all measures from this patient's measure_ids, translates into CMS ids for filtering
          patient_measures = @measures.filter (m) -> _(d.result.patient.get('measure_ids')).contains m.get('hqmf_set_id')
          cms_ids = []
          _(patient_measures).each (m) -> cms_ids.push m.get('cms_id')
          d.result.patient.set({ cms_ids: cms_ids }, { silent: true})

    rendered: ->

      @$('#sharedResults').on 'shown.bs.collapse hidden.bs.collapse', (e) =>
        @bankLogicView.clearRationale()
        if e.type is 'shown'
          @toggledPatient = $(e.target).model().result
          @bankLogicView.showRationale(@toggledPatient)
        else
          @toggledPatient = null
          @showSelectedPatients()

      @$('#sharedResults').on 'show.bs.collapse hidden.bs.collapse', (e) =>
        @$(e.target).prev('.panel-heading').toggleClass('opened-patient')
        @$(e.target).parent('.panel').find('.panel-chevron').toggleClass 'fa-angle-right fa-angle-down'

      @$('select[name=patients-filter]').selectBoxIt # custom styling for dropdown
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
    @listenTo @selectedPatients, 'add remove', _.bind(@showSelectedPatients, this)
    @selectedDifferences = new Thorax.Collection

    # wait so everything calculates
    @listenTo @differences, 'complete', ->
      @$('button[type=submit]').button('ready').removeAttr("disabled")
      @$('.patient-count').text "("+@differences.length+")" # show number of patients in bank
      @showSelectedPatients()

    populations = @model.get('populations')
    @currentPopulation = populations.first()
    populationLogicView = new Thorax.Views.PopulationLogic(model: @currentPopulation)
    if populations.length > 1
      @bankLogicView = new Thorax.Views.PopulationsLogic collection: populations
      @bankLogicView.setView populationLogicView
    else
      @bankLogicView = populationLogicView

    @listenTo @bankLogicView, 'population:update', (population) ->
      @currentPopulation = population # change to reflect the selection
      @createFilters() # need to update filters based on the selected population
      @collection.fetch() # need to update the patient results based on the selected population
      # wait but don't reset toggled patient....
      if @toggledPatient then @bankLogicView.showRationale(@toggledPatient) else @showSelectedPatients()
      # wait but don't reset selected patients..

    @appliedFilters = new Thorax.Collection
    @listenTo @appliedFilters, 'add remove', _.bind(@updateFilteredDisplay, this)
    @availableFilters = new Thorax.Collection
    @createFilters()

  appliedFilterContext: (filter) ->
    _(filter.toJSON()).extend
      label: filter.label()

  differenceContext: (difference) ->
    _(difference.toJSON()).extend
      patient: difference.result.patient.toJSON()
      measure_id: @model.get('hqmf_set_id')
      cms_id: @model.get('cms_id')
      episode_of_care: @model.get('episode_of_care')

  createFilters: ->
    _(@currentPopulation.populationCriteria()).each (criteria) =>
      @availableFilters.add filter: Thorax.Models.PopulationsFilter, name: criteria
    @availableFilters.add filter: Thorax.Models.MeasureAuthorFilter, name: 'Created by...'
    @availableFilters.add filter: Thorax.Models.MeasureFilter, name: 'From measure...'

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
      filter = new filterModel($additionalRequirements.val())
    @appliedFilters.add(filter)
    @updateFilteredDisplay()
    # TODO - don't keed adding endless filters or duplicate filters
    $select.find('option:eq(0)').prop("selected", true).trigger("change")
    $select.data("selectBox-selectBoxIt").refresh() # update dropdown

  removeFilter: (e) ->
    thisFilter = $(e.target).model()
    @appliedFilters.remove(thisFilter)
    @updateFilteredDisplay()

  updateFilteredDisplay: ->
    @updateFilter() # force item-filter to show new results
    @$('.patient-count').text "("+$('.shared-patient:visible').length+")" # updates displayed count of patient bank results
    @filterSelectedPatients() # if needed, adjust the currently selected patient set

  filterSelectedPatients: ->
    # when selected patients get filtered out, properly remove them from selected patients.
    $hiddenPatients = @$('input.select-patient:checked:hidden')
    $hiddenPatients.prop('checked',false).trigger("change")
    $hiddenPatients.each (index, element) =>
      patient = @$(element).model().result.patient
      @selectedPatients.remove patient

  updateFilteredDisplay: ->
    @updateFilter() # force item-filter to show new results
    @$('.patient-count').text "("+$('.shared-patient:visible').length+")" # updates displayed count of patient bank results
    @filterSelectedPatients() # if needed, adjust the currently selected patient set

  changeSelectedPatients: (e) ->
    @$(e.target).closest('.panel-heading').toggleClass('selected-patient')
    patient = @$(e.target).model().result.patient # gets the patient model to add or remove
    if @$(e.target).is(':checked') then @selectedPatients.add patient else @selectedPatients.remove patient

  showSelectedPatients: ->
    #reflects the selected patient across the view
    if @selectedPatients.isEmpty()
      @$('.bank-actions').attr("disabled", true)
      @$('.patient-select-count').html 'Please select patients below.'
      @selectedDifferences.reset @differences.models # show the coverage for everyone
    else
      @$('.bank-actions').removeAttr("disabled")
      if @selectedPatients.length == 1 then @$('.patient-select-count').html '1 patient selected <i class="fa fa-times-circle clear-selected"></i>'
      else @$('.patient-select-count').html @selectedPatients.length + ' patients selected <i class="fa fa-times-circle clear-selected"></i>'
      @selectedDifferences.reset @selectedPatients.map (patient) => @currentPopulation.differenceFromExpected(patient)

    @rationaleCriteria = []
    @selectedDifferences.each (difference) => if difference.get('done')
      result = difference.result
      rationale = result.get('rationale')
      @rationaleCriteria.push(criteria) for criteria, result of rationale when result
    @measureCriteria = @currentPopulation.dataCriteriaKeys()
    @rationaleCriteria = _(@rationaleCriteria).intersection(@measureCriteria)
    if not @toggledPatient then @bankLogicView.showSelectCoverage(@rationaleCriteria) # returns a custom coverage view

  clonePatientIntoMeasure: (patient) ->
    clonedPatient = patient.deepClone(omit_id: true, dedupName: true)
    # store origin patient's data into clone
    origin_data =
      patient_id: patient.get('_id')
      measure_ids: patient.get('measure_ids')
      cms_id: patient.get('cms_id')
      user_id: patient.get('user_id')
      user_email: patient.get('user_email')
    # set clone to this measure, user, and default to unshared
    patient_measures = clonedPatient.get('measure_ids')
    patient_measures[0] = @model.get('hqmf_set_id')
    clonedPatient.set
      'measure_ids': patient_measures,
      'cms_id': @model.get('cms_id'),
      'user_id': @model.get('user_id'),
      'is_shared': false,
      'origin_data': origin_data
    clonedPatient.save clonedPatient.toJSON(),
      success: (patient) =>
        console.log patient
        @patients.add patient # make sure that the patient exist in the global patient collection
        @model.get('patients').add patient # and that measure's patient collection
        if bonnie.isPortfolio
          @measures.each (m) -> m.get('patients').add patient

  cloneOnePatient: (e) ->
    @$(e.target).button('cloning')
    patient = @$(e.target).model().result.patient # gets the patient model to clone
    @clonePatientIntoMeasure(patient)
    @$(e.target).button('cloned')
    @$(e.target).attr("disabled", true)

  cloneBankPatients: (e) ->
    @$(e.target).button('cloning')
    @selectedPatients.each (patient) => @clonePatientIntoMeasure(patient)
    @$(e.target).button('cloned')
    bonnie.navigate "measures/#{@model.get('hqmf_set_id')}" # return to measure
    window.location.reload() # refreshes the measure page so it shows newly imported patients
