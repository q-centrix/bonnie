import DS from 'ember-data';

export default DS.Model.extend({
  population: DS.hasMany('population', {async: false}),
  rationale: DS.attr(),
  IPP: DS.attr('string'),
  STRAT: DS.attr('string'),
  DENOM: DS.attr('string'),
  NUMER: DS.attr('string'),
  DENEXCEP: DS.attr('string'),
  DENEX: DS.attr('string'),
  MSRPOPL: DS.attr('string'),
  OBSERV: DS.attr('string'),
  antinumerator: DS.attr('number'),
  birthdate: DS.attr('date'),
  effective_date: DS.attr('date'),
  ethnicity: DS.attr('string'),
  finalSpecifics: DS.attr(),
  first: DS.attr('string'),
  gender: DS.attr('string'),
  languages: DS.attr(),
  last: DS.attr('string'),
  logger: DS.attr(),
  measure_id: DS.belongsTo('hqmfSet', {async: false}),
  medical_record_id: DS.attr('string'),
  nqf_id: DS.attr('string'),
  patient_id: DS.belongsTo('patient', {async: false}),
  payer: DS.attr(),
  provider_performances: DS.attr(),
  race: DS.attr('string'),
  rationale: DS.attr(),
  sub_id: DS.attr(),
  test_id: DS.attr(),
  isPopulated: function() {
    let rationale = this.get('rationale');
    return (typeof rationale !== "undefined" && rationale !== null);
  }.property('rationale'),
  differenceFromExpected: function(){
    let expected = this.get('patient').get('getExpectedValue')(this.get('population'));
    // create new difference with given patient and population
    let difference = {result: this, expected: expected};
    // new Thorax.Models.Difference({}, result: this, expected: expected)
  }

});
