import { picker } from 'picker/main'
import { userFacingText } from 'user-facing-text/main'

export default () ->
  describe 'picker', ->
    it 'should have user facing text defined', ->
      # XXX: this feels not quite right - we are doing side affecting stuff just
      # by requiring a file...
      userFacingText('picker', 'chooseValue').should.equal('Choose a value...')
