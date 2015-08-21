import Ember from 'ember';
import LoginControllerMixin from 'simple-auth/mixins/login-controller-mixin';

export default Ember.Controller.extend(LoginControllerMixin, {
  identification: null,
  password: null,
  registered: false,
  loginFailed: false,
  actions: {
    authenticate() {
      // quickly exit and avoid the AJAX call if either the email or password is empty
      if(Ember.isEmpty(this.get('identification')) || Ember.isEmpty(this.get('password'))){
        this.set('loginFailed', true);
        return;
      }

      var data = this.getProperties('identification', 'password');
      // wipe the failed message and make the AJAX call to log the user in
      // this._super() is defined by ember-simple-auth in
      // the LoginControllerMixin included in this controller
      this.set('loginFailed', false);
      return this.get('session').authenticate('simple-auth-authenticator:devise', data);
    }
  }
});
