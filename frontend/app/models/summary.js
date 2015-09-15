import DS from 'ember-data';

export default DS.Model.extend({
  successful: DS.attr('number'),
  complete: DS.attr('number'),
  percent: function(){
    let successful = this.get('successful');
    let complete = this.get('complete')
    if(successful !== null && typeof successful === 'number' && this.get('complete')){
      return Math.round(100*successful/complete);
    }
    return 0;
  }.property('successful', 'complete'),
  status: function(){
    if(this.get('successful') > 0){
      return 'pass';
    } else{
      return 'fail';
    }
  }.property('successful'),
  population: DS.belongsTo('population', {async: false, inverse:'summary'})
});
