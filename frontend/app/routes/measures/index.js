import Ember from 'ember';
import AuthenticatedRouteMixin from 'simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin, {
  model() {
    return this.store.findAll('measure');
  },
  setupController: function(controller, model) {
    controller.set('measures', model);
    // since this is loaded via the original call.  This may need to be changed
    //  when the patient bank is added
    controller.set('patients', this.store.peekAll('patient'));
  }
});
