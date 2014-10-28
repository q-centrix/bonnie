## All filter implementations should have an #apply(patient) method that returns true/false.

class Thorax.Models.MeasureAuthorFilter extends Thorax.Model
  additionalRequirements: {name: 'email', text: 'E-mail address'}
  initialize: (@email) ->
  apply: (patient) ->
    # TODO determine if the patient's creator has this filter's email address
  label: -> "E-mail (#{@email})"

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
