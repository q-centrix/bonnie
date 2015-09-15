import Ember from 'ember';

export default Ember.Component.extend({
  didRender: function(){
    this.$('.dial').knob();

  },
  color: function(){
    if(this.get('summary.status') === 'pass'){
      return "#009a65";
    } else if(this.get('summary.status') === 'fail'){
      return "#a52700";
    } else {
      return "#f6f6f6";
    }
  }.property('summary.status')
});
