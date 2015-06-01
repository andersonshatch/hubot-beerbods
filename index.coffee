Path = require 'path'

module.exports = (robot) ->
  path = Path.resolve __dirname, 'src'
  robot.load path
