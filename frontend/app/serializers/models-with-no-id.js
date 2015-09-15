import DS from 'ember-data';
import Ember from 'ember';

export default DS.RESTSerializer.extend({
  isNewSerializerAPI: true,
  extractId(type, hash) {
    return hash.id || Ember.generateGuid(hash, type.modelName);
  }
});
