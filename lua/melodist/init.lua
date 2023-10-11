SCRIPTS_PATH = '../../../../scripts/?.lua'
package.path=table.concat({SCRIPTS_PATH, package.path}, ';')

--------------------------------------------------------------------------------

require 'instruments' -- Done
require 'note' -- Done
require 'pitch' -- Done

-- In progress:
require 'util'
require 'mode'

-- require 'meter' -- require
-- require 'figure' -- require
-- require 'quality' -- require

-- require 'chord' -- require  quality figure
-- require 'scale' -- require chord
-- require 'song' -- require chord figure meter