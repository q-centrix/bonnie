class Thorax.Views.CqlLogic extends Thorax.Views.BonnieView

  template: JST['logic/cql_logic']

  context: ->
    _(super).extend
      identifier: @model.get('elm').library.identifier
      usings: _(@model.get('elm').library.usings.def).select (u) -> u.localId
      valueSets: @model.get('elm').library.valueSets.def
      parameters: @model.get('elm').library.parameters.def
      statements: @model.get('elm').library.statements.def
      cqlLines: @model.get('cql').split("\n")

  showCoverage: ->

  clearCoverage: ->

  showRationale: ->

  clearRationale: ->
