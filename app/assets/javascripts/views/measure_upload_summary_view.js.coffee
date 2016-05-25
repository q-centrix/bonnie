class Thorax.Views.MeasureUploadSummary extends Thorax.Views.BonnieView
  template: JST['measure_upload_summary']

  initialize: ->
    @upload_data = undefined
    $.get('/measures/upload_summary?id='+@summaryId, @loadUpdateSummary)

  loadUpdateSummary: (data) =>
    @upload_data = data   
  
    @render()
    return
  
  