class Thorax.Views.MeasureUploadSummary extends Thorax.Views.BonnieView
  template: JST['measure_upload_summary']

  initialize: ->
    @upload_data = undefined
    $.get('/measures/upload_summary?id='+@summaryId, @loadUpdateSummary)

  events:
    'click .patient-link': 'patientSelected'

  loadUpdateSummary: (data) =>
    @upload_data = data
    @graphicDifferences = {before: {}, after: {}}
    @graphicDifferences.before.done = true
    @graphicDifferences.before.matching = 1
    @graphicDifferences.before.percent = @upload_data.patient_numbers_information.percent_passed_before
    if (@upload_data.patient_numbers_information.percent_passed_before == 100.00)
      @graphicDifferences.before.status = 'pass'
    else
      @graphicDifferences.before.status = 'fail'
    
    @graphicDifferences.after.done = true
    @graphicDifferences.after.matching= 1
    @graphicDifferences.after.percent = @upload_data.patient_numbers_information.percent_passed_after
    if (@upload_data.patient_numbers_information.percent_passed_after == 100.00)
      @graphicDifferences.after.status = 'pass'
    else
      @graphicDifferences.after.status = 'fail'
    @render()
    return
    
  patientSelected: =>  
    @trigger "patient:selected"