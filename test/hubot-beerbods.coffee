Helper = require 'hubot-test-helper'
expect = require('chai').expect
nock = require 'nock'

helper = new Helper('../src')

describe 'hubot-beerbods', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)
		do nock.disableNetConnect

	context 'beerbods returns page with expected layout', ->
		beforeEach (done) ->
			nock("https://beerbods.co.uk")
				.get("/")
				.times(9)
				.replyWithFile(200, __dirname + '/replies/valid.html')
			@room.user.say 'josh', 'hubot beerbods'
			@room.user.say 'josh', 'hubot beerbods some other text'
			@room.user.say 'josh', 'hubot whats this weeks beerbods '
			@room.user.say 'josh', 'hubot whats this weeks beerbods?'
			@room.user.say 'josh', 'hubot what\'s this weeks beerbods'
			@room.user.say 'josh', 'hubot what\'s this weeks beerbods?'
			@room.user.say 'josh', 'hubot what\'s this week\'s beerbods'
			@room.user.say 'josh', 'hubot what\'s this week\'s beerbods?'
			@room.user.say 'josh', 'hubot what’s this week’s beerbods?'
			setTimeout done, 100

		response = ['hubot', 'This week\'s beer is Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
		it 'responds to hubot beerbods', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['josh', 'hubot beerbods some other text']
				['josh', 'hubot whats this weeks beerbods ']
				['josh', 'hubot whats this weeks beerbods?']
				['josh', 'hubot what\'s this weeks beerbods']
				['josh', 'hubot what\'s this weeks beerbods?']
				['josh', 'hubot what\'s this week\'s beerbods']
				['josh', 'hubot what\'s this week\'s beerbods?']
				['josh', 'hubot what’s this week’s beerbods?']
				response
				response
				response
				response
				response
				response
				response
				response
				response
			]

