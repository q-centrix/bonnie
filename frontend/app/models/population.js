import DS from 'ember-data';

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
  differences: function() {
    let calculator = this.get('calculator').get('calculator');
    if(typeof calculator !== "function") return;
    // Should begin by clearing out the old patient results that don't exist
    // Then rerunning any changed occurrences
    // Then add new ones (may be convulted...)
    // stuff into a difference object population and calc models, it will use this to produce results
    // Create the result objects
    this.get('measure').get('hqmf_set_id').get('patients').forEach((patient)=>{
      let result = calculator(patient.toJSON());
      console.log(patient);
      console.log(result);
    });
    // Create the difference (using result function)

    // return a peek on all difference for this population
  }.property('calculator.calculator', 'measure.hqmf_set_id.patients.@each'),
  summary: function() {

  }.property('differences.@each')
});
