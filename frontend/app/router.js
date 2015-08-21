import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('measures/index', { path: '/' });
  this.route('measures/show', { path: '/measures/:id' });
  this.route('login');
});

export default Router;
