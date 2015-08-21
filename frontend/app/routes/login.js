import Ember from 'ember';
import UnauthenticatedRouteMixin from 'simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend(UnauthenticatedRouteMixin, {
  resetController(controller, isExiting) {
    if(isExiting) {
      controller.setProperties({
        email: null,
        password: null,
        registered: false,
        loginFailed: false
      });
    }
  }
});
