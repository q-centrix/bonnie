class Thorax.Views.Cql extends Thorax.Views.BonnieView
  template: JST['cql']
  events:
    "submit form": (event) ->
      event.preventDefault()
      cql = $('#cql').val()
      @model.set(cql: cql)
      post = $.post "measures/cql_to_elm", { cql: cql, authenticity_token: $("meta[name='csrf-token']").attr('content') }
      post.done (response) => @updateElm(response)
      post.fail (response) => @displayErrors(response.responseJSON)
  initialize: ->
    @setModel(new Thorax.Model(elm: ""))
  displayErrors: (response) ->
    errors = response.library.annotation.map (annotation) -> "Line #{annotation.startLine}: #{annotation.message}"
    alert "Errors:\n\n#{errors.join("\n\n")}"
  updateElm: (response) ->
    @model.set(elm: JSON.stringify(response, null, 2))



#library TinyQDM version '4'
#using QDM
#valueset "Ischemic Stroke": '2.16.840.1.113883.3.117.1.7.1.247'
#parameter MeasurementPeriod default Interval[DateTime(2012, 1, 1, 0, 0, 0, 0), DateTime(2013, 1, 1, 0, 0, 0, 0))
#context Patient
    
