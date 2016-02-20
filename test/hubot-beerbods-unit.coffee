Helper = require 'hubot-test-helper'
expect = require('chai').expect
nock = require 'nock'

helper = new Helper('../src')

afterEach ->
	GLOBAL.nockscope.done()

describe 'hubot-beerbods-slack-unit', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)
		@room.robot.adapterName = 'slack'
		@room.robot.slackMessages = []
		@room.robot.on 'slack-attachment', (data) ->
			data.message.robot.slackMessages.push data
		do nock.disableNetConnect

		@attachment = [{
			pretext: 'This week\'s beer:',
			title: 'Beer?, The Dharma Initiative',
			title_link: 'https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative',
			image_url: 'https://beerbods.co.uk/media/108/bottle.png',
			fallback: 'This week\'s beer is Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative',
			fields: [{
				title: 'Untappd',
				value: '<https://untappd.com/search?q=Beer%3F%2C%20The%20Dharma%20Initiative|Search on Untappd>',
				short: true
			}]
		}]

	context 'mock beerbods returns page with expected layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/valid.html')
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(@room.robot.slackMessages).to.have.length 1
			message = @room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_emoji).to.eql ":beers:"
			expect(message.attachments).to.eql @attachment

	context 'mock beerbods returns modified page layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/invalid.html')
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'replies with an apology via normal message', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]
			expect(@room.robot.slackMessages).to.have.length 0

	context 'mock beerbods returns page with expected layout, slack custom identity disabled', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/valid.html')
			process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY = 'true'
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'doesn\'t reply with a normal message, sends slack attachment as hubot', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(@room.robot.slackMessages).to.have.length 1
			message = @room.robot.slackMessages[0]
			expect(message.username).to.be.undefined
			expect(message.icon_imoji).to.be.undefined
			expect(message.attachments).to.eql @attachment


describe 'hubot-beerbods-unit', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)
		do nock.disableNetConnect

	context 'mock beerbods returns page with expected layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
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

	context 'mock beerbods returns modified page layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/invalid.html')
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

	context 'mock beerbods site unavailable', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithError('some http / socket error')
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

	context 'mock beerbods 404', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.reply(404)
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

