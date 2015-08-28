import DS from 'ember-data';

export default DS.RESTAdapter.extend({
  isNewSerializerAPI: true,
  shouldReloadAll() {
    return true;
  },
  headers: {
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  }
});
