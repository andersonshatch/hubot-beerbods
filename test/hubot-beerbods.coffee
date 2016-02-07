Helper = require 'hubot-test-helper'
expect = require('chai').expect
nock = require 'nock'

helper = new Helper('../src')

describe 'hubot-beerbods', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)
		do nock.disableNetConnect
		nock("https://beerbods.co.uk")
			.get("/")
			.replyWithFile(200, __dirname + '/replies/valid.html')

	context 'user says beerbods', ->
		beforeEach (done) ->
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds to hubot beerbods', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'This week\'s beer is Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
			]

	context 'user asks for this weeks beerbods', ->
		beforeEach (done) ->
			@room.user.say 'josh', 'hubot what\'s this weeks beerbods?'
			setTimeout done, 100

		it 'responds to question about this weeks beerbods', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot what\'s this weeks beerbods?']
				['hubot', 'This week\'s beer is Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
			]
