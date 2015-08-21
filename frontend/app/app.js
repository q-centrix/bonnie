import Ember from 'ember';
import Resolver from 'ember/resolver';
import loadInitializers from 'ember/load-initializers';
import config from './config/environment';

var App;

Ember.MODEL_FACTORY_INJECTIONS = true;

// May want to set the app up to defer Routing here
App = Ember.Application.extend({
  rootElement: '#bonnie',
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  ready: function(){
    $('.loading-indicator').hide();
  },
  Resolver: Resolver
});

loadInitializers(App, config.modulePrefix);

export default App;
