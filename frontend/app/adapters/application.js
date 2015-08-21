import ActiveModelAdapter from 'active-model-adapter';

export default ActiveModelAdapter.extend({
  isNewSerializerAPI: true,
  shouldReloadAll() {
    return true;
  },
  headers: {
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  }
});
