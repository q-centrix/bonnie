class Thorax.Models.ArchivedMeasure extends Thorax.Model
  idAttribute: '_id'
  initialize: ->
    # Becasue we bootstrap patients we mark them as _fetched, so isEmpty() will be sensible
    @set 'patients', new Thorax.Collections.Patients [], _fetched: true
  

class Thorax.Collections.ArchivedMeasures extends Thorax.Collection
  url: '/measures'
  model: Thorax.Models.ArchivedMeasure
