class Thorax.Views.MeasurePatientDashboard extends Thorax.Views.BonnieView

  template: JST['measure/patient_dashboard']

  initialize: ->
    @results = []
    @model.get('populations').each (population) =>
      @results.push(population.calculationResults().toJSON())

    @views = []
    @criteria_text_hash = {}
    @criteria_order_list = []

    #Grab all populations related to this measure
    codes = (population['code'] for population in @model.get('measure_logic'))
    @populations = _.intersection(Thorax.Models.Measure.allPopulationCodes, codes)

    # Grab all data criteria and pass them into DataCriteriaLogic
    for reference in Object.keys(@model.get('data_criteria'))
      @dataLogicView = new Thorax.Views.DataCriteriaLogic(reference: reference, measure: @model)
      @views.push(@dataLogicView)

    @population_criteria = {} # "Type" => "Preconditions"
    for code in Thorax.Models.Measure.allPopulationCodes #TODO add multiple population_set support
      if code in Object.keys(@model.get('populations')['models'][0]['attributes'])
        @population_criteria[code] = @model.get('populations')['models'][0].get(code)['preconditions']
        
    @criteria_keys_by_population = @criteria_keys_by_population()
    
    ##DEBUG of VIEWS####
    @view.appendTo('body') for @view in @views
    ###############

    @dispIppColumns = []
    @dispNumerColumns = []
    @dispDenomColumns = []
    @dispDenexcepColumns = []

    @ippColumns = []
    @numerColumns = []
    @denomColumns = []
    @denexcepColumns = []

    @FIXED_ROWS = 2
    @FIXED_COLS = 5 + @populations.length

    @COL_WIDTH_NAME = 140
    @COL_WIDTH_POPULATION = 36
    @COL_WIDTH_META = 100
    @COL_WIDTH_FREETEXT = 240
    @COL_WIDTH_CRITERIA = 180

    @expandedRows = [] # used to ensure that expanded rows stay expanded after re-render
    @editableRows = [] # used to ensure rows marked for inline editing stay that way after re-render

    @editableCols = @getEditableCols() # these are the fields that should be inline editable

  events:
    rendered: ->
      $('.container').removeClass('container').addClass('container-fluid')

    ready: ->
      @createTable()

      # go through every table and adjust the markup generated by HOT
      for table in $('table.htCore')
        $(table).addClass('table')

        header_row1 = $(table).find('tr:not([data-row]):first-child td')
        header_row2 = $(table).find('tr:not([data-row]):nth-child(2) td')

        for cell in header_row1
          unless $(cell).attr('colspan') is undefined
            # replace <td> tags with <th> tags manually
            $(cell).replaceWith(
              '<th colspan='+$(cell).attr('colspan')+
              ' scope="col" class='+$(cell).attr('class')+
              '>'+$(cell).html()+'</th>')
          else if $(cell).attr('style') is "display: none;"
            # ensures table has same number of columns in every row
            $(cell).detach()

        for cell, index in header_row2
          # replace <td> tags with <th> tags manually
          classes = $(cell).attr('class')
          if index >= 5 and index < (5 + @populations.length*2)
            classes = classes + " rotate"

          $(cell).replaceWith('<th scope="col" class='+classes+'>'+$(cell).html()+'</th>')


  createTable: ->
    container = @$('#patient_dashboard_table').get(0)
    patients = @model.get('patients')
    hot = new Handsontable(container, {
      data: @createData(@views, patients),
      colWidths: @getColWidths(),
      copyPaste: false, # need this to avoid 508 issue
      fixedRowsTop: @FIXED_ROWS,
      fixedColumnsLeft: @FIXED_COLS,
      mergeCells: @createMergedCells(@model, patients),
      readOnly: true,
      readOnlyCellClassName: '', # avoid using the default .htDimmed... it'll just make the whole table grey.
      renderAllRows: true, # handsontable's optimizer for rendering doesn't manage hidden rows well. Rendering all to fix.
      renderAllColumns: true, # partial rendering creates unpleasant jiltiness when scrolling horizontally. Rendering all to fix.
      cells: (row, col, prop) =>
        cellProperties = {};
        if row == 0
          cellProperties.renderer = @header1Renderer
        else if row == 1
          cellProperties.renderer = @header2Renderer
        else
          cellProperties.renderer = @dataRenderer
        return cellProperties
      ,
      afterSelection: (rowIndexStart, colIndexStart, rowIndexEnd, colIndexEnd) =>
        if colIndexStart == colIndexEnd && rowIndexStart == rowIndexEnd
          if colIndexStart == 0
            @makeInlineEditable(container, hot, rowIndexStart)
          if colIndexStart == 1
            @toggleExpandableRow(container, rowIndexStart)
          if colIndexStart == 2
            # TODO: figure out what actually needs to be passed into this view to appropraitely pass into the patient edit view
            patientEditView = new Thorax.Views.MeasurePatientEditModal(model: @model.get('patients').models[0], measure: @model, patients: @model.get('patients'), measures = @model.collection)
            patientEditView.appendTo(@$el)
            patientEditView.display()
      })

  makeInlineEditable: (container, hot, rowIndex) =>
    for table in $(container).find('table')
      tr = $(table).find('tr[data-row="row' + rowIndex.toString() + '"]').get(0)
      if tr
        if $(tr).hasClass('inline-edit-mode')
          Handsontable.Dom.removeClass(tr, 'inline-edit-mode')
          @editableRows = @editableRows.filter (index) -> index != rowIndex
        else
          Handsontable.Dom.addClass(tr, 'inline-edit-mode')
          @editableRows.push(rowIndex)

    for col in @editableCols
      if rowIndex in @editableRows
        hot.setCellMeta(rowIndex, col, 'readOnly', false)
      else
        hot.setCellMeta(rowIndex, col, 'readOnly', true)

  toggleExpandableRow: (container, rowIndex) =>
    if rowIndex > 1 && rowIndex%2 == 0
      expandableRowIndex = rowIndex + 1
      for table in $(container).find('table')
        tr = $(table).find('tr[data-row="row' + expandableRowIndex.toString() + '"]').get(0)
        if tr
          if $(tr).hasClass('expandable-hidden')
            Handsontable.Dom.removeClass(tr, 'expandable-hidden')
            Handsontable.Dom.addClass(tr, 'expandable-shown')
            @expandedRows.push(expandableRowIndex)
          else
            Handsontable.Dom.removeClass(tr, 'expandable-shown')
            Handsontable.Dom.addClass(tr, 'expandable-hidden')
            @expandedRows = @expandedRows.filter (index) -> index != expandableRowIndex

  header1Renderer: (instance, td, row, col, value, cellProperties) =>
    Handsontable.renderers.TextRenderer.apply(this, arguments)
    @addDiv(td)
    @getColor(instance, td, row, col, value, cellProperties)

  header2Renderer: (instance, td, row, col, value, cellProperties) =>
    Handsontable.renderers.TextRenderer.apply(this, arguments)
    if col >= 5 && col < (@populations.length * 2) + 5
      @addDiv(td)
    else
      @addScroll(td)

  dataRenderer: (instance, td, row, col, value, cellProperties) =>
    Handsontable.renderers.TextRenderer.apply(this, arguments)
    Handsontable.Dom.addClass(td, 'content')
    @addDiv(td)

    # enabling expandable detail rows. Need to do by a custom data-attribute
    # because of how handsontable efficiently renders the table
    tr = td.parentElement
    $(tr).attr('data-row', "row" + row)
    if row%2 == 1
      if row in @expandedRows
        Handsontable.Dom.addClass(tr, 'expandable-shown')
      else
        Handsontable.Dom.addClass(tr, 'expandable-hidden')
    # enabling edit modes for the table
    if row in @editableRows
      Handsontable.Dom.addClass(tr, 'inline-edit-mode')
      if col in @editableCols
        instance.setCellMeta(row, col, 'readOnly', false)
    if col in @editableCols
      Handsontable.Dom.addClass(td, 'editable')

  getColor: (instance, td, row, col, value, cellProperties) =>
    if @ippColumns[0] <= col && @ippColumns[@ippColumns.length-1] >= col
      Handsontable.Dom.addClass(td, "ipp")
    else if (@numerColumns[0] <= col && @numerColumns[@numerColumns.length-1] >= col)
      Handsontable.Dom.addClass(td, "numer")
    else if (@denomColumns[0] <= col && @denomColumns[@denomColumns.length-1] >= col)
      Handsontable.Dom.addClass(td, "denom")
    else if (@denexcepColumns[0] <= col && @denexcepColumns[@denexcepColumns.length-1] >= col)
      Handsontable.Dom.addClass(td, "denexcep")
    else
      Handsontable.Dom.addClass(td, "basic")

  addDiv: (element) =>
    text = element.textContent
    element.firstChild.remove()
    if text == 'FALSE'
      $(element).append('<div class="text-danger"><i aria-hidden="true" class="fa fa-fw fa-times-circle"></i> ' + text + '</div>')
    else if text == 'TRUE'
      $(element).append('<div class="text-success"><i aria-hidden="true" class="fa fa-fw fa-check-circle"></i> ' + text + '</div>')
    else if text.indexOf('SPECIFIC') >= 0
      $(element).append('<div class="text-danger"><i aria-hidden="true" class="fa fa-fw fa-asterisk"></i> ' + text + '</div>')
    else
      $(element).append('<div>' + text + '</div>')

  addScroll: (element) =>
    text = element.textContent
    element.firstChild.remove()
    $(element).append('<div class="tableScrollContainer"><div class="tableScroll">' + text + '</div></div>')

  # TODO: refactor the processing code below once we know what the patient data model will look like

  getColWidths: ()  =>
    colWidths = []

    # for edit/expand/modal fields
    colWidths.push(@COL_WIDTH_META)
    colWidths.push(@COL_WIDTH_META)
    colWidths.push(@COL_WIDTH_META)

    # for first name and last name
    colWidths.push(@COL_WIDTH_NAME)
    colWidths.push(@COL_WIDTH_NAME)

    # for the expected and actual populations
    colWidths.push(@COL_WIDTH_POPULATION) for [1..@populations.length*2]

    # for the notes
    colWidths.push(@COL_WIDTH_FREETEXT)

    # for birthdate, expired, deathdate
    colWidths.push(@COL_WIDTH_META)
    colWidths.push(@COL_WIDTH_META)
    colWidths.push(@COL_WIDTH_META)

    # for race and ethnicity
    colWidths.push(@COL_WIDTH_FREETEXT)
    colWidths.push(@COL_WIDTH_FREETEXT)

    # for gender
    colWidths.push(@COL_WIDTH_META)

    # for criteria
    for population, criteria_keys of @criteria_keys_by_population
      if criteria_keys
        colWidths.push(@COL_WIDTH_CRITERIA) for [1..criteria_keys.length]
    
    return colWidths

  createData: (measure,patients) =>
    #@getOptionalRows()
    data = []
    headers = @createHeaderRows(measure, patients)
    data.push(headers[0])
    data.push(headers[1])

    @createPatientRows(patients, data)

    return data

  createMergedCells: (measure, patients) =>
    mergedCells = []
    
    currIndex = 3 # starting index for merged cells - ignores the 'button' cells like edit, modal, etc.
    colspans = [2, @populations.length, @populations.length, 7] # name, populations, populations, metadata
    
    for colspan in colspans
      mergedCells.push({row:0, col:currIndex, colspan:colspan, rowspan:1})
      currIndex += colspan

    for population in @populations
      if @criteria_keys_by_population[population]
        colspan = @criteria_keys_by_population[population].length
        mergedCells.push({row: 0, col:currIndex, colspan:colspan, rowspan:1})
        currIndex += colspan

    return mergedCells

  getEditableCols:() =>
    editableCols = []
    
    index = 3
    editableCols.push(index++) # firstname
    editableCols.push(index++) # lastname
    
    # make expected population results editable
    for population in @populations
      editableCols.push(index++)
    
    # hop over the actual population results
    for population in @populations
      index++
      
    # TODO: these values are hard coded because the metadata values are hard coded. there is probably a better way to represent this.
    editableCols.push(index++) # notes
    editableCols.push(index++) # birthdate
    
    return editableCols

  createHeaderRows: (measure, patients) =>

    row2 = ['EDIT','EXPAND','MODAL','First Name','Last Name']
    attributes = ['Notes','Birthdate','Expired','Deathdate','Ethnicity','Race','Gender']

    row1 = ['','','','Name','']
    populations_array_placeholder = new Array(@populations.length-1).join(".").split(".")

    row1.push('Expected')
    row1 = row1.concat(populations_array_placeholder)

    row1.push('Actual')
    row1 = row1.concat(populations_array_placeholder)
    row1 = row1.concat(['Metadata','','','','','',''])
    
    for population in @populations
      if @criteria_keys_by_population[population]
        row1.push(population)
        row1.push('') for [1..@criteria_keys_by_population[population].length-1]

    #TODO There must be a better way to duplicate items in list.
    for population in @populations
      row2.push(population)
    for population in @populations
      row2.push(population)
    row2 = row2.concat(attributes)

    population_code_data_criteria_map = {}

    for @view in measure
      @criteria_text_hash[@view.dataCriteria.key] = @view.$el[0].outerText

    for code in Thorax.Models.Measure.allPopulationCodes
      if @criteria_keys_by_population[code]?
        for criteria in @criteria_keys_by_population[code]
          row2.push(@criteria_text_hash[criteria])
          @criteria_order_list.push(criteria)

#    curColIndex = row2.length
#    @createHeaderSegment(row1, row2, @dispIppColumns, @population_criteria['IPP'], @ippColumns, curColIndex, "IPP")
#    curColIndex = row2.length
#    @createHeaderSegment(row1, row2, @dispNumerColumns, @population_criteria['NUMER'], @numerColumns, curColIndex, "NUMER")
#    curColIndex = row2.length
#    @createHeaderSegment(row1, row2, @dispDenomColumns, @population_criteria['DENOM'], @denomColumns, curColIndex, "DENOM")
#    curColIndex = row2.length
#    @createHeaderSegment(row1, row2, @dispDenexcepColumns, @population_criteria['DENEXCEP'], @denexcepColumns, curColIndex, "DENEXCEP")

    [row1, row2]

  createHeaderSegment: (row1, row2, useColumnsArray, measureColumns, colIndexArray, curColIndex, headerString) =>
    isFirstRow = true
    colIndexArray.length = 0
    for value in useColumnsArray
      if isFirstRow
        row1.push(headerString)
      else
        row1.push("")
      row2.push(' ')
      #row2.push(measureColumns[value])
      colIndexArray.push(curColIndex)
      curColIndex++
      isFirstRow = false

  createPatientRows: (patients, data) =>
    for patient, i in patients.models
      patientRow = @createPatientRow(patient);
      patientDetailRow = @createPatientDetailRow(patient, i, patientRow);
      data.push(patientRow);
      data.push(patientDetailRow);

  createPatientRow: (patient) =>

     patient_values = ['EDIT','EXPAND','MODAL']
     patient_attributes = ['notes','birthdate','expired','deathdate','ethnicity','race','gender']
     #Match results to patients.
     patient_result = @match_patient_to_patient_id(patient.id)

     patient_values.push(patient.get('first'))
     patient_values.push(patient.get('last'))
     #Get the expected values from patient object. First must match to measure_ids
     patient_values = patient_values.concat(@extract_patient_expected_values(patient, @populations))
     #Get the actual values from patient object.
     patient_values = patient_values.concat(@extract_value_for_population_type(patient_result, @populations))

     #Add patient attribute values to patient value array.
     for attribute in patient_attributes
       patient_values.push(patient.get(attribute))

     data_criteria_values = @extract_data_criteria_value(patient_result)
     patient_values = patient_values.concat(data_criteria_values)

  match_patient_to_patient_id: (patient_id) =>
    patients = @results[0] #TODO will need to add population_set support
    # Iterate over each of the patients to match the patient_id
    patient = (patient for patient in patients when patient.patient_id == patient_id)[0]

  extract_patient_expected_values: (patient, populations) =>
    expected_model = (model for model in patient.get('expected_values').models when model.get('measure_id') == @model.get('hqmf_set_id'))[0]
    expected_values = []
    for population in populations
      if population not in expected_model.keys()
        expected_values.push(0)
      else
        expected_values.push(expected_model.get(population))
    return expected_values

  # populates the array with actual values for each population
  extract_value_for_population_type: (patient_result, populations) =>
    patient_actuals = []
    for population in populations
      if population == 'OBSERV'
        if population of patient_result #TODO investigate observe
          console.log("In Observ if statment")
        else
          patient_actuals.push(0)
      else if population of patient_result
        patient_actuals.push(patient_result[population])
      else
        patient_actuals.push('X')
    return patient_actuals

  # Extracts the data_criteria values for each patient.
  extract_data_criteria_value: (patient_result) =>  #TODO Clean up
    data_criteria_values = []
    for criteria in @criteria_order_list
      if criteria of patient_result['rationale']
        value = patient_result['rationale'][criteria]
        if value != null && value != 'false' && value != false
          data_criteria_values.push('TRUE')
        else if value == 'false' || value == false
          data_criteria_values.push('FALSE')
        else
          data_criteria_values.push(value)
      else
        data_criteria_values.push('')
    return data_criteria_values

#TODO Fill in headers correctly
#TODO Specific occurrence code
#TODO Observ code
#TODO Fix all over TODOs

    # Change value if specific rationale is involved.
#    if @patient[:specificsRationale] && @patient[:specificsRationale][population_type]
#      specific_value = @patient[:specificsRationale][population_type][criteria_key]

      # value could be "false", nil, "true"
#      if specific_value == "false" && value == "TRUE"
#        value = "SPECIFICALLY FALSE"
#      elsif specific_value == "true" && value == "FALSE"
#        value = "SPECIFICALLY TRUE"
#      end
#    end

#    return value
#  end

############################## Measure Criteria Keys ##############################

  # Given a data criteria, return the list of all data criteria keys referenced within, either through
  # children criteria or temporal references; this includes the passed in criteria reference
  data_criteria_criteria_keys: (criteria_reference) =>
    criteria_keys = [criteria_reference]
    if criteria = @model.get('data_criteria')[criteria_reference]
      if criteria['children_criteria']?
        criteria_keys = criteria_keys.concat(@data_criteria_criteria_keys(criteria) for criteria in criteria['children_criteria'])
        criteria_keys = flatten(criteria_keys)
      if criteria['temporal_references']?
        criteria_keys = criteria_keys.concat(@data_criteria_criteria_keys(temporal_reference['reference']) for temporal_reference in criteria['temporal_references'])
        criteria_keys = flatten(criteria_keys)

    return criteria_keys

  # Given a precondition, return the list of all data criteria keys referenced within
  precondition_criteria_keys: (precondition) =>
    if precondition['preconditions'] && precondition['preconditions'].length > 0
      results = (@precondition_criteria_keys(precondition) for precondition in precondition['preconditions'])
      results = flatten(results)
    else if precondition['reference']
      @data_criteria_criteria_keys(precondition['reference'])
    else
      []

  # Return the list of all data criteria keys in this measure, indexed by population code
  criteria_keys_by_population: () =>
    criteria_keys_by_population = {}
    for name, precondition of @population_criteria
      if precondition?
        criteria_keys_by_population[name] = @precondition_criteria_keys(precondition[0]).filter (ck) -> ck != 'MeasurePeriod'
    criteria_keys_by_population

#TODO Make this coffeescript. Or use underscore.js
  `function flatten(arr) {
    const flat = [].concat(...arr)
    return flat.some(Array.isArray) ? flatten(flat) : flat;
  }`

###################################################################################

  createPatientDetailRow: (patient, rowIndex, patientSummaryRow) =>
    row = [];
    for value in patientSummaryRow
      row.push("DETAIL " + rowIndex.toString())
    return row

    @createPatientSegment(ret, @dispIppColumns, patient.ipp);
    @createPatientSegment(ret, @dispNumerColumns, patient.numer);
    @createPatientSegment(ret, @dispDenomColumns, patient.denom);
    @createPatientSegment(ret, @dispDenexcepColumns, patient.denexcep);

    return ret;

  createPatientSegment: (row, dispColumns, patientColumn) =>
    for value in dispColumns
      row.push(patientColumn[value])

  getOptionalRows: ->
    @dispIppColumns.length = 0
    @dispNumerColumns.length = 0
    @dispDenomColumns.length = 0
    @dispDenexcepColumns.length = 0
    for key, value of @demoMeasure.ipp
      @dispIppColumns.push(key)
    for key, value of @demoMeasure.numer
      @dispNumerColumns.push(key)
    for key, value of @demoMeasure.denom
      @dispDenomColumns.push(key)
    for key, value of @demoMeasure.denexcep
      @dispDenexcepColumns.push(key)

class Thorax.Views.MeasurePatientEditModal extends Thorax.Views.BonnieView
  template: JST['measure/patient_edit_modal']

  events:
    'ready': 'setup'

  initialize: ->
    @patientBuilderView = new Thorax.Views.PatientBuilder(model: @model, measure: @measure, patients: @patients, measures: @measures, showCompleteView: false)

  setup: ->
    @editDialog = @$("#patientEditModal")

  display: ->
    @editDialog.modal(
      "backdrop" : "static",
      "keyboard" : true,
      "show" : true).find('.modal-dialog').css('width','900px') # The same width defined in $modal-lg

  save: (e)->
    status = @patientBuilderView.save(e)
    if status
      @editDialog.modal(
        "backdrop" : "static",
        "keyboard" : false,
        "show" : true)
      @editDialog.modal('hide')

  close: -> ''
