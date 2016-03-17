Helper = require 'hubot-test-helper'
expect = require('chai').expect

helper = new Helper('../src')

describe 'hubot-beerbods-integration-slack', ->
	beforeEach ->
		@room = helper.createRoom(httpd:false)
		@room.robot.adapterName = 'slack'
		@room.robot.slackMessages = []
		@room.robot.on 'slack-attachment', (data) ->
			data.message.robot.slackMessages.push data

	context 'actual beerbods returns page with expected layout', ->
		beforeEach (done) ->
			@room.user.say 'josh', 'hubot beerbods'
			setTimeout done, 1500

		it 'doesn\'t reply with a normal message, sends slack attachment', ->
			expect(@room.messages).to.eql [
				['josh', 'hubot beerbods']
			]

			expect(@room.robot.slackMessages).to.have.length 1
			message = @room.robot.slackMessages[0].attachments[0]
			expect(message.pretext).to.eql 'This week\'s beer:'
			expect(message.title).to.be.defined
			expect(message.title_link).to.match /https:\/\/beerbods.co.uk\/.*/
			expect(message.image_url).to.match /https:\/\/beerbods.co.uk\/.*/
			expect(message.fallback).to.match /This week\'s beer is .* https:\/\/beerbods.co.uk\/.*/
			expect(message.fields[0].title).to.eql 'Untappd'
			expect(message.fields[0].value).to.match /<https:\/\/untappd.com\/search?q=.*|Search on Untappd>/
			expect(message.fields[0].short).to.eql true

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

describe 'hubot-beerbods-integration-archive', ->
	beforeEach ->
		@room = helper.createRoom(httpd: false)

	context 'actual beerbods returns archive page with expected layout', ->
		beforeEach (done) ->
			@room.user.say 'josh', 'hubot what was last week\'s beerbods?'
			setTimeout done, 1500

		it 'replies with last week\'s beer', ->
			expect(@room.messages).to.have.length 2
			expect(@room.messages[1]).to.match /Last week's beer was .* https:\/\/beerbods.co.uk\/.*/

