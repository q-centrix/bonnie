import DS from 'ember-data';

export default DS.Model.extend({
  measure: DS.belongsTo('measure'),
  patients: DS.hasMany('patients'),
  patient_maintainer: DS.hasMany('patients'),
  expected_values: DS.hasMany('expectedValue')
});
