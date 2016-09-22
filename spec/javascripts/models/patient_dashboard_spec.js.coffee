describe 'PatientDashboard', ->
  
  beforeEach ->
    jasmine.getJSONFixtures().clearCache()
    @measure = bonnie.measures.findWhere(cms_id: 'CMS128v5')
    
    # getting the population sets relevant to the model (IPP, DENOM, etc.)
    codes = (population['code'] for population in @measure.get('measure_logic'))
    @populations = _.intersection(Thorax.Models.Measure.allPopulationCodes, codes)
    
    @populationSet = @measure.get('populations').at(0)
    
    # need to pass in defined widths
    widths =
      population: 30
      meta_huge: 200
      meta_large: 110
      meta_medium: 100
      meta_small: 40
      freetext: 240
      criteria: 200
      result: 80
    @patientDashboard = new Thorax.Models.PatientDashboard @measure, @populations, @populationSet, widths

  it 'initialized properly', ->
    expectedCriteriaKeys = {}
    expectedCriteriaKeys['IPP'] = ['Agegrtr_thn_eql_18yearsat_017BF72A_2885_4350_B259_80D19397C35F_8C7B3095_A649_4913_A90D_11A5AE59387E',
                                   'qdm_var_SatisfiesAny_9D7195EC_6B92_4B06_BAD9_5888FAF7E6B8_7C54FB26_C89F_4630_8044_5676529EE9C5',
                                   'qdm_var_SatisfiesAny_899DFA04_7197_4DB9_8E22_3DE5B351FE79_15479A20_DCBF_423F_A895_FDEEDB4F44BF',
                                   'During_108F51AF_1144_4F16_ABC6_B1ED2B2DB800_92C21CCE_9DD7_4A9D_AC39_A40DEFF1E643']
    expectedCriteriaKeys['DENOM'] = []
    expectedCriteriaKeys['DENEX'] = ['less_thn_eql_105daysStartsBeforeStartOf_0457E84E_FAC2_4D58_815C_EAED430BB231_43B4B0F6_EA34_42B4_95B2_6A943CABDF52']
    expectedCriteriaKeys['NUMER'] = ['less_thn_eql_114daysEndsAfterStartOf_01B99489_936F_47EC_A457_7151F9049A75_988EB0D7_AC7A_41BE_90DC_ACEE9C6B575E']
    
    expect(@patientDashboard.criteriaKeysByPopulation).toEqual(expectedCriteriaKeys)
