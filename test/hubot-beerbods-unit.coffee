Helper = require 'hubot-test-helper'
expect = require('chai').expect
nock = require 'nock'

helper = new Helper('../src')

beforeEach ->
	global.room = helper.createRoom(httpd: false)
	do nock.disableNetConnect

afterEach ->
	global.nockscope.done()

configureRoomForSlack = ->
	global.room.robot.adapterName = 'slack'
	global.room.robot.slackMessages = []
	global.room.robot.on 'slack-attachment', (data) ->
		data.message.robot.slackMessages.push data

describe 'hubot-beerbods-slack-unit', ->
	beforeEach ->
		do configureRoomForSlack
		#nasty hack to allow modifying the @attachment and current-0 in individual tests
		str = JSON.stringify(require('./expected/slack-attachment.json'))
		@attachment = JSON.parse(str)
		current0str = JSON.stringify(require('./replies/current-0.json'))
		@current0 = JSON.parse(current0str)

	context 'mock beerbods api returns beer and untappd data', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(200, @current0)
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(global.room.messages[0]).to.eql ['josh', 'hubot beerbods']

			expect(global.room.robot.slackMessages).to.have.length 1
			#Slack message will be emitted as a slack-attachment for the v3.x adapter, as a message object for v4.x
			#... check that they are both the same as we expect
			expect(global.room.robot.slackMessages[0]).to.eql global.room.messages[1][1]
			message = global.room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_url).to.eql "https://beerbods.co.uk/images/favicon.ico"
			expect(message.attachments).to.eql @attachment

	context 'mock beerbods api returns an error', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.replyWithError("intentional mock request fail")
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'replies with an apology via normal message', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
			]
			expect(global.room.robot.slackMessages).to.have.length 0

	context 'mock beerbods api returns a non 200 status', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(404, '', [])
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'replies with an apology via normal message', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
			]
			expect(global.room.robot.slackMessages).to.have.length 0

	context 'mock beerbods api returns beer and untappd data without rating', ->
		beforeEach (done) ->
			response = @current0
			delete response.beers[0].untappd.rating
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(200, response)
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(global.room.messages[0]).to.eql ['josh', 'hubot beerbods']

			expect(global.room.robot.slackMessages).to.have.length 1
			expect(global.room.robot.slackMessages[0]).to.eql global.room.messages[1][1]
			message = global.room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_url).to.eql "https://beerbods.co.uk/images/favicon.ico"
			expect(message.attachments).to.eql(require './expected/slack-attachment-no-rating-or-abv.json')

	context 'mock beerbods api returns beer and untappd data without abv', ->
		beforeEach (done) ->
			response = @current0
			delete response.beers[0].untappd.abv
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(200, response)
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(global.room.messages[0]).to.eql ['josh', 'hubot beerbods']

			expect(global.room.robot.slackMessages).to.have.length 1
			expect(global.room.robot.slackMessages[0]).to.eql global.room.messages[1][1]
			message = global.room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_url).to.eql "https://beerbods.co.uk/images/favicon.ico"
			@attachment[0].fields = [@attachment[0].fields[0], @attachment[0].fields[2]]
			expect(message.attachments).to.eql @attachment

	context 'mock beerbods api returns beer and untappd data without description', ->
		beforeEach (done) ->
			response = @current0
			delete response.beers[0].untappd.description
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(200, response)
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'doesn\'t reply with a normal message, sends slack attachment as beerbods', ->
			expect(global.room.messages[0]).to.eql ['josh', 'hubot beerbods']

			expect(global.room.robot.slackMessages).to.have.length 1
			expect(global.room.robot.slackMessages[0]).to.eql global.room.messages[1][1]
			message = global.room.robot.slackMessages[0]
			expect(message.username).to.eql "beerbods"
			expect(message.icon_url).to.eql "https://beerbods.co.uk/images/favicon.ico"
			@attachment[0].fields = [@attachment[0].fields[0], @attachment[0].fields[1]]
			expect(message.attachments).to.eql @attachment

	context 'mock beerbods api returns beer and untappd data, slack custom identity disabled', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.replyWithFile(200, __dirname + '/replies/current-0.json')
			process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY = 'true'
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'doesn\'t reply with a normal message, sends slack attachment as hubot', ->
			expect(global.room.messages[0]).to.eql ['josh', 'hubot beerbods']

			expect(global.room.robot.slackMessages).to.have.length 1
			expect(global.room.robot.slackMessages[0]).to.eql global.room.messages[1][1]
			message = global.room.robot.slackMessages[0]
			expect(message.username).to.be.undefined
			expect(message.icon_url).to.be.undefined
			expect(message.attachments).to.eql @attachment



describe 'hubot-beerbods-unit', ->
	context 'mock beerbods api returns page with expected layout', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.times(8)
				.replyWithFile(200, __dirname + '/replies/current-0.json')
			global.room.user.say 'josh', 'hubot beerbods'
			global.room.user.say 'josh', 'hubot whats this weeks beerbods '
			global.room.user.say 'josh', 'hubot whats this weeks beerbods?'
			global.room.user.say 'josh', 'hubot what\'s this weeks beerbods'
			global.room.user.say 'josh', 'hubot what\'s this weeks beerbods?'
			global.room.user.say 'josh', 'hubot what\'s this week\'s beerbods'
			global.room.user.say 'josh', 'hubot what\'s this week\'s beerbods?'
			global.room.user.say 'josh', 'hubot what’s this week’s beerbods?'
			setTimeout done, 50

		response = ['hubot', 'This week\'s test beer shall be Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
		it 'responds to hubot beerbods', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot beerbods']
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
			]

	context 'mock beerbods api returns no body for previous', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/previous/0.json").reply(200)
				.get("/v1/previous/1.json").reply(200)
				.get("/v1/previous/2.json").reply(200)
				.get("/v1/previous/3.json").reply(200)
			global.room.user.say 'josh', 'hubot what was last week\'s beerbods?'
			global.room.user.say 'josh', 'hubot beerbods -2'
			global.room.user.say 'josh', 'hubot beerbods -3'
			global.room.user.say 'josh', 'hubot beerbods -4'
			setTimeout done, 50

		it 'responds with an apology', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot what was last week\'s beerbods?']
				['josh', 'hubot beerbods -2']
				['josh', 'hubot beerbods -3']
				['josh', 'hubot beerbods -4']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
			]

	context 'mock beerbods api valid for next weeks beer', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/1.json")
				.replyWithFile(200, __dirname + '/replies/current-1.json')
			global.room.user.say 'josh', 'hubot what\'s next week\'s beerbods?'
			setTimeout done, 50

		it 'responds with next weeks beer', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot what\'s next week\'s beerbods?']
				['hubot', 'Next week\'s test beer shall be Dalrympley, Hikin - https://beerbods.co.uk/this-weeks-beer/dalrymple-hikin']
			]

	context 'mock beerbods api valid for last weeks beer', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/previous/0.json")
				.times(3)
				.replyWithFile(200, __dirname + '/replies/current-0.json')
			global.room.user.say 'josh', 'hubot what\'s last week\'s beerbods?'
			global.room.user.say 'josh', 'hubot beerbods -1'
			global.room.user.say 'josh', 'hubot beerbods prev'
			setTimeout done, 50

		it 'responds with last weeks beer', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot what\'s last week\'s beerbods?']
				['josh', 'hubot beerbods -1']
				['josh', 'hubot beerbods prev']
				['hubot', 'This week\'s test beer shall be Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
				['hubot', 'This week\'s test beer shall be Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
				['hubot', 'This week\'s test beer shall be Beer?, The Dharma Initiative - https://beerbods.co.uk/this-weeks-beer/beer-dharma-initiative']
			]

	context 'mock beerbods api unavailable', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.replyWithError('intentional mock request fail')
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'responds with an apology', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
			]

	context 'mock beerbods api 404', ->
		beforeEach (done) ->
			global.nockscope = nock("https://beerbods.andersonshatch.com")
				.get("/v1/current/0.json")
				.reply(404)
			global.room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 50

		it 'responds with an apology', ->
			expect(global.room.messages).to.eql [
				['josh', 'hubot beerbods']
				['hubot', 'Sorry, there was an error finding beers. Please check https://beerbods.co.uk']
			]

