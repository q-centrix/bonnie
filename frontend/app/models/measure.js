import DS from 'ember-data';

export default DS.Model.extend({
  bundle_id: DS.attr('string'),
  category: DS.attr('string'),
  cms_id: DS.attr('string'),
  complexity: DS.belongsTo('complexity', { async: false }),
  continuous_variable: DS.attr('boolean'),
  created_at: DS.attr('date'),
  custom_functions: DS.attr(),
  data_criteria: DS.attr(),
  description: DS.attr('string'),
  episode_ids: DS.attr(),
  episode_of_care: DS.attr('boolean'),
  force_sources: DS.attr(),
  hqmf_id: DS.attr(),
  hqmf_set_id: DS.belongsTo('hqmfSet', { async: false, inverse: 'measure'}),
  measure_id: DS.attr('string'),
  measure_logic: DS.attr(),
  measure_period: DS.attr(),
  needs_finalize: DS.attr('boolean'),
  population_criteria: DS.attr(),
  populations: DS.hasMany("population", { async: false, inverse:'measure'}),
  preconditions: DS.attr(),
  publish_date: DS.attr(),
  source_data_criteria: DS.attr(),
  title: DS.attr('string'),
  type: DS.attr('string'),
  updated_at: DS.attr('date'),
  user_id: DS.attr(),
  value_set_oids: DS.attr(),
  version: DS.attr('string'),
  patients: function(){
    return this.get('hqmf_set_id.patients');
  }.property('hqmf_set_id.patients')
});
