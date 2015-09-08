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
  measure_id: DS.belongsTo('measure', {async: false}),
  medical_record_id: DS.attr('string'),
  nqf_id: DS.attr('string'),
  patient_id: DS.belongsTo('patient', {async: false}),
  payer: DS.attr(),
  population: DS.belongsTo('population', {async: false}),
  provider_performances: DS.attr(),
  race: DS.attr(),
  rationale: DS.attr(),
  sub_id: DS.attr(),
  test_id: DS.attr(),
  isPopulated: function() {
    let rationale = this.get('rationale');
    return (typeof rationale !== "undefined" && rationale !== null);
  }.property('rationale'),
  differenceFromExpected: function(){
    let expected = this.get('patient').get('expected_values').filter((expected)=>{
      return expected.get('measure.id') === this.get('population.measure.id');
    }).objectAt(0);
    // TODO: create the expected value if it doesn't exist
    // create new difference with given patient and population (use ids to prevent unnecessary duplication)
    let difference = {difference:{result: this.get('id'), expected: expected.get('id')}};
    this.store.pushPayload('difference', difference);
    return this.store.filter('difference', (difference) => {
      return difference.get('result').get('id') === this.get('id');
    });
  }

});
