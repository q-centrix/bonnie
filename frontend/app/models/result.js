import DS from 'ember-data';

export default DS.Model.extend({
  IPP: DS.attr('number', {defaultValue: 0}),
  STRAT: DS.attr('number', {defaultValue: 0}),
  DENOM: DS.attr('number', {defaultValue: 0}),
  NUMER: DS.attr('number', {defaultValue: 0}),
  DENEXCEP: DS.attr('number', {defaultValue: 0}),
  DENEX: DS.attr('number', {defaultValue: 0}),
  MSRPOPL: DS.attr('number', {defaultValue: 0}),
  OBSERV: DS.attr(),
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
  values: DS.attr(),
  isPopulated: function() {
    let rationale = this.get('rationale');
    return (typeof rationale !== "undefined" && rationale !== null);
  }.property('rationale'),
  differenceFromExpected: function(){
    let expected = this.get('patient_id.expected_values').filter((expected)=>{
      return expected.get('measure_id.measure.id') === this.get('population.measure.id');
    }).objectAt(0);
    // TODO: create the expected value if it doesn't exist
    // create new difference with given patient and population (use ids to prevent unnecessary duplication)
    let difference = {difference:{result: this.get('id'), expected: expected.get('id'), population: this.get('population.id')}};
    this.store.pushPayload('difference', difference);
    return this.store.filter('difference', (difference) => {
      return difference.get('result.id') === this.get('id');
    }).then(function(differences){
      return differences.objectAt(0);
    });
  }

});
