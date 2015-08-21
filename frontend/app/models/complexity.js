import DS from 'ember-data';

export default DS.Model.extend({
  populations: DS.hasMany("population"),
  variables: DS.attr()
});
