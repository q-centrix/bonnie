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
    cmsId = @cmsId.slice(0,3).toUpperCase() + @cmsId.replace('V','v').slice(3) # format CMS id so it can match
    targetMeasure = bonnie.measures.findWhere(cms_id: cmsId) # TODO only works with user's measures - needs to know every measure
    _(patient.get('measure_ids')).any (hqmfSetId) -> targetMeasure.get('hqmf_set_id') is hqmfSetId
  label: -> @cmsId

class Thorax.Models.PopulationsFilter extends Thorax.Model
  initialize: (@criteria, @population) ->

  apply: (patient) ->
    calculation = @population.calculate(patient)
    result = calculation.get @criteria
    if result? then result # if it calculates true, return the patient

  label: -> @criteria
