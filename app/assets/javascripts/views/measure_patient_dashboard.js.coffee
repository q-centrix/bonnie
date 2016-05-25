class Thorax.Views.MeasurePatientDashboardLayout extends Thorax.LayoutView
  template: JST['measure/patient_dashboard_layout']
  className: 'patient-dashboard-layout'

  switchPopulation: (e) ->
    @population = $(e.target).model()
    @population.measure().set('displayedPopulation', @population)
    @setView new Thorax.Views.MeasurePopulationPatientDashboard(measure: population.measure(), population: @population)
    @trigger 'population:update', @population

  populationContext: (population) ->
    _(population.toJSON()).extend
      isActive:  population is population.measure().get('displayedPopulation')
      populationTitle: population.get('title') || population.get('sub_id')

  setView: (view) ->
    results = @population.calculationResults()
    results.calculationsComplete =>
      view.results = results
      super(view)

class Thorax.Views.MeasurePopulationPatientDashboard extends Thorax.Views.BonnieView
  template: JST['measure/patient_dashboard']
  className: 'patient-dashboard'

  initialize: ->
    #Grab all populations related to this measure
    @patientEditView = new Thorax.Views.MeasurePatientEditModal(dashboard: this)

    codes = (population['code'] for population in @measure.get('measure_logic'))
    @populations = _.intersection(Thorax.Models.Measure.allPopulationCodes, codes)

    @pd = new Thorax.Models.PatientDashboard(@measure,@populations,@population)

    @FIXED_ROWS = 2
    @FIXED_COLS = @getFixedColumnCount()

    @editableRows = [] # used to ensure rows marked for inline editing stay that way after re-render

    @editableCols = @getEditableCols() # these are the fields that should be inline editable

    @results = @population.calculationResults()
    @results.calculationsComplete =>
      @patientResults = @results.toJSON()
      container = @$('#patient_dashboard_table').get(0)
      patients = @measure.get('patients')
      patientData = @createData(patients)
      @widths = @getColWidths()
      @head1 = patientData.slice(0,1)[0]
      @head2 = patientData.slice(1,2)[0]
      @data = patientData.slice(2)

  context: ->
    _(super).extend
      patients: @data
      head1: @head1
      head2: @head2
      widths: @widths

  events:
    rendered: ->
      $('.container').removeClass('container').addClass('container-fluid')
      @patientEditView.appendTo(@$el)
    destroyed: ->
      $('.container-fluid').removeClass('container-fluid').addClass('container')

    ready: ->
      @patientData = []
      for patient in @measure.get('patients').models
        @patientData.push new Thorax.Models.PatientDashboardPatient patient, @pd, @measure, @matchPatientToPatientId(patient.id), @populations, @population
      table = $('#patientDashboardTable').DataTable({
        data: @patientData,
        columns: @getTableColumns(@patientData[2]),
        #autoWidth: false,
        #columns: @getColWidths(),
        scrollX: true,
        scrollY: "500px",
        paging: false,
        fixedColumns: { leftColumns: 5 }
      })

  getTableColumns: (patient) ->
    column = []
    column.push data: 'editButtonDiv' # Inline edit button
    column.push data: 'openButtonDiv' # Patient editing modal button
    column.push data: 'firstname'
    column.push data: 'lastname'
    column.push data: 'description'
    for k, v of patient._expected
      column.push data: 'expected_' + k
    for k, v of patient._actual
      column.push data: 'actual_' + k
    column.push data: 'passes'
    column.push data: 'birthdate'
    column.push data: 'deathdate'
    column.push data: 'gender'
    # Collect all actual data criteria a sort to make sure patient dashboard
    # displays dc in the correct order.
    dcStartIndex = @pd._dataInfo['gender'].index + 1
    dc = []
    for k, v of @pd._dataInfo
      if v.index >= dcStartIndex
        v['name'] = k
        dc.push v
    dc.sort (a, b) -> a.index - b.index
    for entry in dc
      column.push data: entry.name
    column

  getColWidths: ()  =>
    colWidths = []
    for dataKey in @pd.dataIndices
      colWidths.push(@pd.getWidth(dataKey))
    colWidths

  createData: (patients) =>
    data = []
    headers = @createHeaderRows(patients)
    data.push(headers[0])
    data.push(headers[1])

    return data

  # TODO: this should be done differently and more dynamically
  getFixedColumnCount: () =>
    @pd.getCollectionLastIndex('expected') + 1

  getEditableCols:() =>
    #editableFields = ["first", "last", "notes", "birthdate", "ethnicity", "race", "gender", "deathdate"]
    editableFields = ["first", "last", "notes", "birthdate", "gender", "deathdate"]
    editableCols = []

    for editableField in editableFields
      editableCols.push(@pd.getIndex(editableField))

    # make expected population results editable
    for population in @populations
      editableCols.push(@pd.getIndex('expected' + population))

    return editableCols

  makeInlineEditable: ->
    console.log 'edit'
    # do something here

  openEditDialog: ->
    console.log 'open'
    # show @patientEditView

  createHeaderRows: (patients) =>
    row1 = []
    row2 = []

    for data in @pd.dataIndices
      row2.push(@pd.getName(data))

    row1.push('') for i in [1..row2.length]

    for key, dataCollection of @pd.dataCollections
      row1[dataCollection.firstIndex] = dataCollection.name

    [row1, row2]

  matchPatientToPatientId: (patient_id) =>
    patient = @results.findWhere({patient_id: patient_id}).toJSON()

class Thorax.Views.MeasurePatientEditModal extends Thorax.Views.BonnieView
  template: JST['measure/patient_edit_modal']

  events:
    'ready': 'setup'

  setup: ->
    @editDialog = @$("#patientEditModal")

  display: (model, measure, patients, measures) ->
    @patientBuilderView = new Thorax.Views.PatientBuilder(model: model, measure: measure, patients: patients, measures: measures, showCompleteView: false)
    @patientBuilderView.appendTo(@$('.modal-body'))
    @editDialog.modal(
      "backdrop" : "static",
      "keyboard" : true,
      "show" : true).find('.modal-dialog').css('width','80%') # The same width defined in $modal-lg

  save: (e)->
    @patientBuilderView.save(e)
    @editDialog.modal('hide')
    @$('.modal-body').empty() # clear out patientBuilderView
    # @dashboard.createTable()

  close: ->
    @$('.modal-body').empty() # clear out patientBuilderView
