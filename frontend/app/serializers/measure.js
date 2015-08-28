import DS from 'ember-data';

export default DS.RESTSerializer.extend(DS.EmbeddedRecordsMixin, {
  isNewSerializerAPI: true,
  attrs: {
    complexity: {
      embedded : 'always'
    },
    hqmfSetId: {
      embedded : 'always'
    },
    populations: {
      embedded : 'always'
    }
  }
});
