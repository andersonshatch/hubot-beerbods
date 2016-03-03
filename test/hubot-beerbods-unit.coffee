Helper = require 'hubot-test-helper'
expect = require('chai').expect
nock = require 'nock'

helper = new Helper('../src')

beforeEach ->
	GLOBAL.room = helper.createRoom(httpd: false)
	do nock.disableNetConnect

afterEach ->
	GLOBAL.nockscope.done()

configureRoomForSlack = ->
	GLOBAL.room.robot.adapterName = 'slack'
	GLOBAL.room.robot.slackMessages = []
	GLOBAL.room.robot.on 'slack-attachment', (data) ->
		data.message.robot.slackMessages.push data

describe 'hubot-beerbods-slack-unit', ->
	beforeEach ->
		do configureRoomForSlack
		@attachment = require './expected/slack-attachment.json'

	context 'mock beerbods returns page with expected layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/valid.html')
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			message = GLOBAL.room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_emoji).to.eql ":beers:"
			expect(message.attachments).to.eql @attachment

	context 'mock beerbods returns modified page layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/invalid.html')
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'replies with an apology via normal message', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]
			expect(GLOBAL.room.robot.slackMessages).to.have.length 0

	context 'mock beerbods returns page with expected layout, slack custom identity disabled', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithFile(200, __dirname + '/replies/valid.html')
			process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY = 'true'
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'doesn\'t reply with a normal message, sends slack attachment as hubot', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			message = GLOBAL.room.robot.slackMessages[0]
			expect(message.username).to.be.undefined
			expect(message.icon_imoji).to.be.undefined
			expect(message.attachments).to.eql @attachment

describe 'hubot-beerbods-slack-untappd-unit', ->
	beforeEach ->
		process.env.HUBOT_BEERBODS_UNTAPPD_CLIENT_ID = 'not-real-id'
		process.env.HUBOT_BEERBODS_UNTAPPD_CLIENT_SECRET = 'not-real-secret'
		@untappdScope = nock("https://api.untappd.com")
		@searchUrl = "/v4/search/beer?q=#{encodeURIComponent 'Beer?, The Dharma Initiative'}&limit=1&client_id=not-real-id&client_secret=not-real-secret"
		@infoUrl = '/v4/beer/info/481516?compact=true&client_id=not-real-id&client_secret=not-real-secret'
		GLOBAL.room.user.say 'josh', 'hubot beerbods'
		GLOBAL.nockscope = nock("https://beerbods.co.uk")
			.get("/")
			.replyWithFile(200, __dirname + '/replies/valid.html')

		do configureRoomForSlack

	afterEach ->
		@untappdScope.done()

	context 'mock services return valid responses, 1 match on untappd', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-search.json')
			@untappdScope.get(@infoUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-info.json')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and untappd details', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			@attachment = require './expected/slack-untappd-attachment.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment

	context 'mock services return valid responses, 2 matches on untappd', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/search-with-more-than-one-result.json')
			setTimeout done, 100

		it 'sends slack attachment with untappd search link', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			@attachment = require './expected/slack-attachment.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment

	context 'mock services return valid responses, 2 matches on untappd, only one in production', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-search-only-one-in-production-beer.json')
			@untappdScope.get(@infoUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-info.json')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and untappd details', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			@attachment = require './expected/slack-untappd-attachment.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment

	context 'valid beerbods response, 1 untappd match without description', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-search.json')
			@untappdScope.get(@infoUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-info-no-description.json')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and partial untappd details', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			@attachment = require './expected/slack-untappd-attachment-no-description.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment

	context 'valid beerbods response, 1 untappd match with 1 rating, no abv', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-search.json')
			@untappdScope.get(@infoUrl)
				.replyWithFile(200, __dirname + '/replies/untappd/valid-info-one-rating-no-abv.json')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and properly formatted untappd details', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 1
			@attachment = require './expected/slack-untappd-attachment-one-rating-no-abv.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment

	context 'valid beerbods and untappd search response, untappd details failure', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.twice()
				.replyWithFile(200, __dirname + '/replies/untappd/valid-search.json')
			@untappdScope.get(@infoUrl)
				.reply(404)
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			GLOBAL.nockscope.interceptors[0].replyWithFile(200, __dirname + '/replies/valid.html') #repeat beerbods request
			@untappdScope.get(@infoUrl)
				.replyWithError('some http / socket error')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and untappd search link', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods'],
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 2
			@attachment = require './expected/slack-attachment.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment
			expect(GLOBAL.room.robot.slackMessages[1].attachments).to.eql @attachment

	context 'valid beerbods, failure on untappd search response', ->
		beforeEach (done) ->
			@untappdScope.get(@searchUrl)
				.reply(404)
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			GLOBAL.nockscope.interceptors[0].replyWithFile(200, __dirname + '/replies/valid.html') #repeat beerbods request
			@untappdScope.get(@searchUrl)
				.replyWithError('some http / socket error')
			setTimeout done, 100

		it 'sends slack attachment including beerbods and untappd search link', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['josh', 'hubot beerbods']
			]

			expect(GLOBAL.room.robot.slackMessages).to.have.length 2
			@attachment = require './expected/slack-attachment.json'
			expect(GLOBAL.room.robot.slackMessages[0].attachments).to.eql @attachment
			expect(GLOBAL.room.robot.slackMessages[1].attachments).to.eql @attachment

describe 'hubot-beerbods-unit', ->
	context 'mock beerbods returns page with expected layout', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.times(9)
				.replyWithFile(200, __dirname + '/replies/valid.html')
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			GLOBAL.room.user.say 'josh', 'hubot beerbods some other text'
			GLOBAL.room.user.say 'josh', 'hubot whats this weeks beerbods '
			GLOBAL.room.user.say 'josh', 'hubot whats this weeks beerbods?'
			GLOBAL.room.user.say 'josh', 'hubot what\'s this weeks beerbods'
			GLOBAL.room.user.say 'josh', 'hubot what\'s this weeks beerbods?'
			GLOBAL.room.user.say 'josh', 'hubot what\'s this week\'s beerbods'
			GLOBAL.room.user.say 'josh', 'hubot what\'s this week\'s beerbods?'
			GLOBAL.room.user.say 'josh', 'hubot what’s this week’s beerbods?'
			setTimeout done, 100

		response = ['hubot', 'This week\'s beer is Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
		it 'responds to hubot beerbods', ->
			expect(GLOBAL.room.messages).to.eql [
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
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

	context 'mock beerbods site unavailable', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.replyWithError('some http / socket error')
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

	context 'mock beerbods 404', ->
		beforeEach (done) ->
			GLOBAL.nockscope = nock("https://beerbods.co.uk")
				.get("/")
				.reply(404)
			GLOBAL.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 100

		it 'responds with an apology', ->
			expect(GLOBAL.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding this week\'s beer. Check https://beerbods.co.uk']
			]

