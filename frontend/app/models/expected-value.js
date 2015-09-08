import DS from 'ember-data';

export default DS.Model.extend({
  measure_id: DS.belongsTo('hqmfSet', {async: false, inverse: 'expected_values'}),
  population_index: DS.attr('number'),
  IPP: DS.attr('number'),
  STRAT: DS.attr('number'),
  DENOM: DS.attr('number'),
  NUMER: DS.attr('number'),
  DENEXCEP: DS.attr('number'),
  DENEX: DS.attr('number'),
  MSRPOPL: DS.attr('number'),
  OBSERV: DS.attr(),
  patient: DS.belongsTo('patient')
});
