import DS from 'ember-data';
import Ember from 'ember';

export default DS.Model.extend({
  IPP: DS.attr('string'),
  STRAT: DS.attr('string'),
  DENOM: DS.attr('string'),
  NUMER: DS.attr('string'),
  DENEXCEP: DS.attr('string'),
  DENEX: DS.attr('string'),
  MSRPOPL: DS.attr('string'),
  OBSERV: DS.attr('string'),
  sub_id: DS.attr('string'),
  measure: DS.belongsTo('measure', { async: false}),
  // This is a "links" set in the measure serializer
  calculator: DS.belongsTo('calculator', { async: true, inverse:'population'}),
  differences: DS.hasMany('difference', { async: false}),
  finished: DS.attr('boolean'),
  summary: DS.belongsTo('summary', {async: false}),
  // IDEA:  The next two functions can be placed on the calculator model and modify the population model
  differencesGenerator: function() {
    // IDEA: Turn this into a generator, add population and inverse to difference, and create a differences: hasMany that holds onto this stuff
    let calculator = this.get('calculator.calculator');
    let patients = this.get('measure.hqmf_set_id.patients');
    if(typeof calculator !== "function" || !Ember.isArray(patients)) {
      return;
    }
    // Should begin by clearing out the old patient results that don't exist
    // Then rerunning any changed occurrences
    // Then add new ones (may be convulted...)
    // stuff into a difference object population and calc models, it will use this to produce results
    // Create the result objects
    patients.forEach((patient)=>{
      let resultPayload = {result: calculator(patient.toJSON())};
      resultPayload.result.population = this.get('id');
      this.store.pushPayload('result', resultPayload);
    });
    // Get all the result models for this population
    let results = this.store.filter('result', (result) => {
      return result.get('population.id') === this.get('id');
    });
    // Create the difference (using result function)
    return results.then((results) => {
      results.forEach((result) => {
        result.differenceFromExpected();
      });
      this.set('finished', true);
    });
  }.observes('calculator.calculator', 'measure.hqmf_set_id.patients.@each'),
  summaryGenerator: function() {
    // IDEA: create a summary model and use that, this will just generate them
    if(this.get('finished')){
      if(this.get('summary')){
        this.get('summary').deleteRecord();
      }
      let complete = 0;
      let successful = 0;
      this.get('differences').forEach((difference) => {
        if(difference.get('match')){
          successful++;
          complete++;
        } else{
          complete++;
        }
      });
      this.store.pushPayload('summary', {summary: {complete: complete, successful: successful, population: this.get('id')}});
    }
  }.observes('differences','finished')
});
