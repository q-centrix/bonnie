class Thorax.Views.BankFilters extends Thorax.Views.BonnieView
  template: JST['patient_bank/filters']
  events:
    'change select':  'supplyExtraFilterInput'
    'submit form':    'addFilter'

    rendered: ->
      @createFilters(@population)
      @$('select').selectBoxIt # custom styling for dropdown
        downArrowIcon: "bank-dropdown-arrow",
        defaultText: "calculates for...",
        autoWidth: false,
        theme:
          button: "bank-dropdown-button"
          list: "bank-dropdown-list"
          container: "bank-dropdown-container"
          focus: "bank-dropdown-focus"
      @$('select').data("selectBox-selectBoxIt").refresh() # update dropdown

  initialize: ->
    @appliedFilters = new Thorax.Collection
    @availableFilters = new Thorax.Collection

  appliedFilterContext: (filter) ->
    _(filter.toJSON()).extend
      label: filter.label()

  createFilters: (population) ->
    @availableFilters.reset()
    _(population.populationCriteria()).each (criteria) =>
      @availableFilters.add filter: Thorax.Models.PopulationsFilter, name: criteria
    @availableFilters.add filter: Thorax.Models.MeasureAuthorFilter, name: 'Created by...'
    @availableFilters.add filter: Thorax.Models.MeasureFilter, name: 'From measure...'

  addFilter: (e) ->
    e.preventDefault()
    $form = $(e.target)
    $select = $form.find('select')
    $additionalRequirements = $form.find('input[name=additional_requirements]')
    filterModel = $select.find(':selected').model().get('filter')
    if $select.val() in @population.populationCriteria()
      filter = new filterModel($select.val(),@population)
    else
      filter = new filterModel($additionalRequirements.val())
    @appliedFilters.add(filter)
    $select.find('option:eq(0)').prop("selected", true).trigger("change")

  removeFilter: (e) ->
    thisFilter = $(e.target).model()
    @appliedFilters.remove(thisFilter)

  supplyExtraFilterInput: ->
    @$('input[name="additional_requirements"]').remove() # remove any filter added previously
    filterModel = @$('select[name=patients-filter]').find(':selected').model().get('filter') # get relevant filter type
    additionalRequirements = filterModel::additionalRequirements
    if additionalRequirements?
      # FIXME use a partial, this is a lot of markup
      input = "<input type='#{additionalRequirements.type}' class='form-control' name='additional_requirements' placeholder='#{additionalRequirements.text}'>"
      div = @$('.additional-requirements')
      $(input).hide().appendTo(div).animate({width: 'toggle'},"fast")
