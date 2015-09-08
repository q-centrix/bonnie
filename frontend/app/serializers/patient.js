import DS from 'ember-data';

export default DS.RESTSerializer.extend(DS.EmbeddedRecordsMixin, {
  isNewSerializerAPI: true,
  extractId(type, hash) {
    return hash._id;
  },
  normalizeResponse (store, primaryModelClass, payload, id, requestType) {
    let ethnicity = payload.ethnicity;
    let payer = 'OT';
    let race = payload.race;
    if(ethnicity != null && ethnicity.code) {
      ethnicity = ethnicity.code;
    }
    let insurance_provs = payload.insurance_providers;
    if(insurance_provs != null && insurance_provs[0] != null &&
      insurance_provs[0].type) {
        payer = insurance_provs[0].type;
      }
    if(race != null && race.code) {
      race = race.code;
    }
    payload.ethnicity = ethnicity;
    payload.payer = payer;
    payload.race = race;
    return this._super(store, primaryModelClass, payload, id, requestType);
  },
  attrs: {
    measureId: {
      embedded : 'always'
    },
    measureIds: {
      embedded : 'always'
    },
    expectedValues: {
      embedded : 'always'
    }
  }
});
