import DS from 'ember-data';

export default DS.Model.extend({
  _id: DS.attr('string'),
  birthdate: DS.attr(),
  bundle_id: DS.attr(),
  conditions: DS.attr(),
  created_at: DS.attr(),
  deathdate: DS.attr(),
  description: DS.attr('string'),
  description_category: DS.attr('string'),
  effective_time: DS.attr(),
  encounters: DS.attr(),
  ethnicity: DS.attr(),
  expected_values: DS.hasMany('expectedValues', { async: false, inverse: 'patient' }),
  expired: DS.attr('boolean'),
  first: DS.attr('string'),
  gender: DS.attr('string'),
  insurance_providers: DS.attr(),
  is_shared: DS.attr('boolean'),
  languages: DS.attr(),
  last: DS.attr('string'),
  marital_status: DS.attr('string'),
  // Need to figure out the purpose of this.  Is it the creator?
  measure_id: DS.belongsTo('hqmfSet', {inverse: 'patient_maintainer'}),
  measure_ids: DS.hasMany('hqmfSet', {inverse: 'patients'}),
  measure_period_end: DS.attr(),
  measure_period_start: DS.attr(),
  medical_record_assigner: DS.attr(),
  medical_record_number: DS.attr(),
  medications: DS.attr(),
  notes: DS.attr(),
  origin_data: DS.attr(),
  payer: DS.attr(),
  procedures: DS.attr(),
  race: DS.attr(),
  religious_affiliation: DS.attr(),
  source_data_criteria: DS.attr(),
  test_id: DS.attr(),
  title: DS.attr('string'),
  type: DS.attr('string'),
  updated_at: DS.attr(),
  user_id: DS.attr(),
  vital_signs: DS.attr()
});