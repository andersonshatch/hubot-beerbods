Helper = require 'hubot-test-helper'
expect = require('chai').expect

helper = new Helper('../src')

describe 'hubot-beerbods-integration', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)

	context 'actual beerbods returns page with expected layout', ->
		beforeEach (done) ->
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 1500

		it 'replies to hubot beerbods with this week\'s beer', ->
			expect(@room.messages).to.have.length 2
			expect(@room.messages[1]).to.match /This week's beer is .* https:\/\/beerbods.co.uk\/.*/

