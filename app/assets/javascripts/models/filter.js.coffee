## All filter implementations should have an #apply(patient) method that returns true/false.

class Thorax.Models.MeasureAuthorFilter extends Thorax.Model
  additionalRequirements: {name: 'email', text: 'E-mail address', type: 'email'}
  initialize: (@email) ->
  apply: (patient) ->
    # TODO determine if the patient's creator has this filter's email address... do we need to ask the server?
  label: -> "E-mail (#{@email})"

class Thorax.Models.MeasureFilter extends Thorax.Model
  additionalRequirements: {name: 'cms_id', text: 'CMS ID', type: 'text'}
  initialize: (@cmsId) ->
  apply: (patient) ->
    targetMeasure = bonnie.measures.findWhere(cms_id: @cmsId)
    _(patient.get('measure_ids')).any (hqmfSetId) -> targetMeasure.get('hqmf_set_id') is hqmfSetId
  label: -> @cmsId

class Thorax.Models.PopulationsFilter extends Thorax.Model
  initialize: (@population, @criteria) ->

  apply: (patient) ->
    calculation = @population.calculate(patient)
    result = calculation.get @criteria
    if result?
      # we're already calculated, just return the result
      result
    else
      # listen to when the calculation is
      # TODO one trigger per filter
      # calculation.one 'finished', => @trigger 'filter madness'
      false

  label: -> @criteria
