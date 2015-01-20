class Thorax.Views.PatientBankView extends Thorax.Views.BonnieView
  template: JST['patient_bank/patient_bank']
  events:
    'change input.select-patient':          'changeSelectedPatients'

    collection:
      sync: ->
        # calculate all the differences for all patients and all populations
        @model.get('populations').each (population) =>
          population_differences = @collection.map (patient) => population.differenceFromExpected(patient)
          @allDifferences.add population_differences
        # set the differences to those calculated for the currently selected population
        @allDifferences = @allDifferences.groupBy (difference) -> difference.result.population.get('index')
        @differences.reset @allDifferences[@currentPopulation.get('index')]

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
          @showSelectedCoverage()

      @$('#sharedResults').on 'show.bs.collapse hidden.bs.collapse', (e) =>
        @$(e.target).prev('.panel-heading').toggleClass('opened-patient')
        @$(e.target).parent('.panel').find('.panel-chevron').toggleClass 'fa-angle-right fa-angle-down'

  initialize: ->
    @collection = new Thorax.Collections.Patients
    @differences = new Thorax.Collections.Differences
    @selectedPatients = new Thorax.Collection
    @listenTo @selectedPatients, 'reset', -> @$('input.select-patient:checked').prop('checked',false).trigger("change")
    @listenTo @selectedPatients, 'add remove reset', _.bind(@showSelectedCoverage, this)

    @allDifferences = new Thorax.Collection

    # wait so everything calculates
    @listenTo @differences, 'complete', ->
      @$('button[type=submit]').button('ready').removeAttr("disabled")
      @$('.patient-count').text "("+@differences.length+")"
      @showSelectedCoverage()

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
      @bankFilterView.population = @currentPopulation
      @bankFilterView.createFilters()
      @differences.reset @allDifferences[@currentPopulation.get('index')]
      # make sure whatever patients are selected or toggled still hold
      if @toggledPatient
        associatedDifference = @differences.filter (d) => _(d.result.patient).isEqual @toggledPatient.patient
        @$('[data-model-cid="'+associatedDifference[0].cid+'"]').find("[data-toggle='collapse']").click()
      unless @selectedPatients.isEmpty()
        associatedDifferences = @differences.filter (d) => @selectedPatients.contains d.result.patient
        _(associatedDifferences).each (d) ->
          @$('[data-model-cid="'+d.cid+'"]').find('input.select-patient').prop('checked',true).trigger("change")

    @bankFilterView = new Thorax.Views.BankFilters population: @currentPopulation
    @bankFilterView.listenTo @bankFilterView.appliedFilters, 'add remove', =>
      @updateFilter() # force item-filter to show new results
      @showFilteredPatientCount()
      # when selected patients get filtered out, properly remove them from selected patients.
      $hiddenPatients = @$('input.select-patient:checked:hidden')
      $hiddenPatients.prop('checked',false).trigger("change")
      # if a toggled patients get filtered out
      $hiddenToggledPatient = @$("[data-parent='#sharedResults']:not(.collapsed):hidden")
      $hiddenToggledPatient.click()

    @selectedPatientsView = new Thorax.Views.SelectedPatients collection: @selectedPatients
    @selectedPatientsView.listenTo @selectedPatients, 'add remove reset', => @selectedPatientsView.render()

  patientFilter: (difference) ->
    patient = difference.result.patient
    @bankFilterView.appliedFilters.all (filter) -> filter.apply(patient)

  differenceContext: (difference) ->
    _(difference.toJSON()).extend
      patient: difference.result.patient.toJSON()
      cms_id: @model.get('cms_id')

  showFilteredPatientCount: ->
    @$('.patient-count').text "("+@$('.shared-patient:visible').length+")" # thorax 'filters' models with $.hide and $.show

  changeSelectedPatients: (e) ->
    @$(e.target).closest('.panel-heading').toggleClass('selected-patient')
    patient = @$(e.target).model().result.patient # gets the patient model to add or remove
    if @$(e.target).is(':checked') then @selectedPatients.add patient else @selectedPatients.remove patient
    if @selectedPatients.isEmpty() then @$('.bank-actions').attr("disabled", true) else @$('.bank-actions').removeAttr("disabled")

  showSelectedCoverage: ->
    selectedDifferences = new Thorax.Collection
    if @selectedPatients.isEmpty()
      selectedDifferences.reset @differences.models # show the coverage for everyone
    else
      selectedDifferences.reset @differences.filter (d) => @selectedPatients.contains d.result.patient
    @rationaleCriteria = []
    selectedDifferences.each (difference) => if difference.get('done')
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

  exportBankPatients: ->
    @exportPatientsView.exporting()
    patients = @selectedPatients.map (p) -> p.id
    $.fileDownload "patients/export",
      successCallback: => @exportPatientsView.banksuccess()
      failCallback: => @exportPatientsView.fail()
      httpMethod: "POST"
      data:
        authenticity_token: $("meta[name='csrf-token']").attr('content'),
        patients: patients
