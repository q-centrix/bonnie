import DS from 'ember-data';

export default DS.Model.extend({
  calculator_str: DS.attr('string'),
  population: DS.belongsTo('population'),
  calculator: function() {
    //executes the code and uses it to set the calculator
    let matching = null;
    let population_criteria_fn = null;
    return eval(`(${this.get('calculator_str')});`);
  }.property('calculator_str')
});
