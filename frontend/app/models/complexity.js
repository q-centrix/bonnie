import DS from 'ember-data';

export default DS.Model.extend({
  populations: DS.attr(),
  measure: DS.belongsTo("measure"),
  variables: DS.attr()
});
