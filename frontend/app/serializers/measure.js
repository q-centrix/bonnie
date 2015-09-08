import DS from 'ember-data';
import Ember from 'ember';

export default DS.RESTSerializer.extend(DS.EmbeddedRecordsMixin, {
  isNewSerializerAPI: true,
  normalizeResponse (store, primaryModelClass, payload, id, requestType) {
    if(Ember.isArray(payload.measures)){
      payload.measures.forEach(function(measure){
        if(Ember.isArray(measure.populations)){
          measure.populations.forEach(function(population, index){
            // Create the calculator json object with links object
            population.links = {calculator: `/measures/${measure.id}/populations/${index}/calculate_code.js`};
            population.index = index;
          });
        }
      });
    }
    return this._super(store, primaryModelClass, payload, id, requestType);
  },
  attrs: {
    complexity: {
      embedded : 'always'
    },
    hqmfSetId: {
      embedded : 'always'
    },
    populations: {
      embedded : 'always'
    }
  }
});
