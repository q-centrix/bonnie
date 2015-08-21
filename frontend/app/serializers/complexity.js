import DS from 'ember-data';
import ModelsWithNoId from './models-with-no-id';

export default ModelsWithNoId.extend(DS.EmbeddedRecordsMixin, {
  isNewSerializerAPI: true,
  attrs: {
    populations: {
      embedded : 'always'
    }
  }
});
