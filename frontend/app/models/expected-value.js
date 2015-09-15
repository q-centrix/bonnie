import DS from 'ember-data';
import Ember from 'ember';

export default DS.Model.extend({
  measure_id: DS.belongsTo('hqmfSet', {async: false, inverse: 'expected_values'}),
  population_index: DS.attr('number'),
  IPP: DS.attr('number', {defaultValue: 0}),
  STRAT: DS.attr('number', {defaultValue: 0}),
  DENOM: DS.attr('number', {defaultValue: 0}),
  NUMER: DS.attr('number', {defaultValue: 0}),
  DENEXCEP: DS.attr('number', {defaultValue: 0}),
  DENEX: DS.attr('number', {defaultValue: 0}),
  MSRPOPL: DS.attr('number', {defaultValue: 0}),
  OBSERV: DS.attr(),
  patient: DS.belongsTo('patient'),
  populationCriteria() {
    let defaults = Ember.copy(bonnie.allPopulationCodes);
    defaults.splice(defaults.indexOf('OBSERV', 1));
    // create OBSERV_index keys for multiple OBSERV values
    let observ = this.get('OBSERV');
    if( observ !== null && typeof observ !== 'undefined' && observ.length) {
      for(let x = 0; x < observ.length; x++) {
        defaults.push(`OBSERV_${x+1}`);
      }
    }
    return defaults;
  },
  isMatch(result) {
    // account for OBSERV if an actual value exists
    let observ = this.get('OBSERV');
    let observIsDefined = (observ !== null && typeof observ !== 'undefined');
    if( observIsDefined ) {
      if( result.get('values') && result.get('values').length ){
        let values = [];
        for(let res of result.get('values')) {
          values.push(undefined);
        }
        this.set('OBSERV', values);
      }
    }
    else {
      if( result.get('values') && result.get('values').length ) {
        let obsResDiff = observ.length - result.get('values').length;
        if( obsResDiff < 0 ) {
          for(let obsRes of obsResDiff) {
            observ.push(undefined);
          }
          this.set('OBSERV', observ);
        }
      }
    }
    let resValues = result.get('values');
    let resultValuesDefined = (resValues !== null && typeof resValues !== 'undefined');
    let populationCriteria = this.populationCriteria();
    for(let popCrit of populationCriteria) {
      let notEqual = true;
      if( popCrit.indexOf('OBSERV') !== -1 ) {
        if(observIsDefined === resultValuesDefined) {
          notEqual = false;
          if(observ[this.observIndex(popCrit)] !== resValues[this.observIndex(popCrit)]) {
            notEqual = true;
          }
        }
        if(notEqual){
          return false;
        }
      }
      else{
        if(this.get(popCrit) !== result.get(popCrit)){
          return false;
        }
      }
    }
    return true;
  },
  observIndex(observKey) {
    return observKey.split('_')[1] - 1;
  }
});
