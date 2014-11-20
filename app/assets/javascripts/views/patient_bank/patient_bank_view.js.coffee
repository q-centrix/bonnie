class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'change select[name=patients-filter]':  'supplyExtraFilterInput'
    'submit form':                          'addFilter'
    'change input.select-patient':          'changeSelectedPatients'
    'click .clear-selected':                (e) -> @$('input.select-patient:checked').prop('checked',false).trigger("change")

    collection:
      sync: ->
        # add calculated patients for those in this measure
        @collectionThisMeasure = @collection.filter (patient) => _(patient.get('measure_ids')).contains @model.get('hqmf_set_id')
        @differences.reset @collectionThisMeasure.map (patient) => @currentPopulation.differenceFromExpected(patient)
        # add the other patients without setting expectations
        @collectionOtherMeasures = @collection.filter (patient) => !_(patient.get('measure_ids')).contains @model.get('hqmf_set_id')
        @differences.add @collectionOtherMeasures.map (patient) => @currentPopulation.differenceFromUnexpected(patient)

        @$('.patient-count').text "("+@differences.length+")" # show number of patients in bank
        @bankLogicView.showSelectCoverages(@differences,@currentPopulation) # set coverage view
        # @bankLogicView.showCoverage()

    rendered: ->
      @exportPatientsView = new Thorax.Views.ExportPatientsView() # Modal dialogs for exporting
      @exportPatientsView.appendTo(@$el)

      @$('#sharedResults').on 'shown.bs.collapse hidden.bs.collapse', (e) =>
        @bankLogicView.clearRationale()
        if e.type is 'shown'
          @toggledPatient = $(e.target).model().result
          @bankLogicView.showRationale(@toggledPatient)
        else
          @toggledPatient = null
          @updateDisplayedCoverage()

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
    @listenTo @selectedPatients, 'add remove', _.bind(@updateDisplayedCoverage, this)

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
    @availableFilters.add filter: Thorax.Models.MeasureAuthorFilter, name: 'Created by...'
    @availableFilters.add filter: Thorax.Models.MeasureFilter, name: 'From measure...'

    # after everything calculates
    @listenTo @differences, 'complete', ->
      @$('button[type=submit]').button('ready').removeAttr("disabled") # enable filters

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
    $hiddenPatients.prop('checked',false).trigger("change") # resets checkboxes
    $hiddenPatients.each (index, element) =>
      patient = @$(element).model().result.patient
      @selectedPatients.remove patient

  clearSelectedPatients: ->
    @$('input.select-patient:checked').prop('checked',false).trigger("change") # resets checkboxes
    @selectedPatients.reset() # empties collection
    @updateSelectedCount()

  changeSelectedPatients: (e) ->
    @$(e.target).closest('.panel-heading').toggleClass('selected-patient')
    patient = @$(e.target).model().result.patient # gets the patient model to add or remove
    if @$(e.target).is(':checked') then @selectedPatients.add patient else @selectedPatients.remove patient
    # updates displayed count of selected patients, handles button enabling
    if !@selectedPatients.isEmpty()
      @$('.bank-actions').removeAttr("disabled")
      if @selectedPatients.length == 1 then @$('.patient-select-count').html '1 patient selected <i class="fa fa-times-circle clear-selected"></i>'
      else @$('.patient-select-count').html @selectedPatients.length + ' patients selected <i class="fa fa-times-circle clear-selected"></i>'
    else
      @$('.bank-actions').attr("disabled", true)
      @$('.patient-select-count').html 'Please select patients below.'

  supplyExtraFilterInput: ->
    @$('input[name="additional_requirements"]').remove() # remove any filter added previously
    filterModel = @$('select[name=patients-filter]').find(':selected').model().get('filter') # get relevant filter type
    additionalRequirements = filterModel::additionalRequirements
    if additionalRequirements?
      # FIXME use a partial, this is a lot of markup
      input = "<input type='#{additionalRequirements.type}' class='form-control' name='additional_requirements' placeholder='#{additionalRequirements.text}'>"
      div = @$('.additional-requirements')
      $(input).hide().appendTo(div).animate({width: 'toggle'},"fast")

  updateDisplayedCoverage: ->
    if !@$('.shared-patient > .in').length # only show coverage if no patients are expanded
      if @selectedPatients.isEmpty()
        @bankLogicView.showSelectCoverages(@differences,@currentPopulation) # all the patient bank patients
      else
        @selectedDifferences = new Thorax.Collections.Differences
        @differences.filter (difference) =>
          if _.contains @selectedPatients.models, difference.result.patient
            @selectedDifferences.add difference
        @bankLogicView.showSelectCoverages(@selectedDifferences,@currentPopulation) # selected patient bank patients

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

    console.log clonedPatient

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

  exportBankPatients: (e) ->
    @exportPatientsView.exporting()

    @$(e.target).button('exporting')
    # get the already-calculated differences for selected patients only
    @selectedDifferences = new Thorax.Collections.Differences
    @differences.filter (difference) =>
      if _.contains @selectedPatients.models, difference.result.patient
        @selectedDifferences.add difference

    # from pivotal: Implementation note: each patient record should probably
    # only be exported against the measure it was originally built for.
    # (We may want to consider scoop and filter against both measures?)

    # format for exporting
    differences = []
    @model.get('populations').each (population) =>
      # differences.push(_(population.differencesFromExpected().toJSON()).extend(population.coverage().toJSON()))
      # differences.push _.extend(@selectedDifferences.toJSON(), population.coverage().toJSON())

    $.fileDownload "patients/export?hqmf_set_id=#{@model.get('hqmf_set_id')}",
      successCallback: => @exportPatientsView.success()
      failCallback: => @exportPatientsView.fail()
      httpMethod: "POST"
      data: {authenticity_token: $("meta[name='csrf-token']").attr('content'), results: differences }

    @$(e.target).button('exported')
    # bonnie.navigate "measures/#{@model.get('hqmf_set_id')}" # return to measure
    # window.location.reload() # refreshes the measure page so it shows newly imported patients
