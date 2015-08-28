import DS from 'ember-data';

export default DS.Model.extend({
  measure_id: DS.belongsTo('hqmfSet', {async: false, inverse: 'expected_values'}),
  population_index: DS.attr('number'),
  IPP: DS.attr('string'),
  STRAT: DS.attr('string'),
  DENOM: DS.attr('string'),
  NUMER: DS.attr('string'),
  DENEXCEP: DS.attr('string'),
  DENEX: DS.attr('string'),
  MSRPOPL: DS.attr('string'),
  OBSERV: DS.attr('string'),
  patient: DS.belongsTo('patient')
});
