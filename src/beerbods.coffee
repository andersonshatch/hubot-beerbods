# Description:
#   Have hubot tell you about BeerBods beers
#
# Configuration:
#    HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY (optional, when true disables overriding username and image with slack adapter)
#    HUBOT_DISABLE_BEERBODS_PLUS (optional, when true disables beerbods plus reply with slack adapter)
#
# Commands:
#    hubot beerbods - Find out what beer is this week's beerbods
#    beerbods <-4,-3,-2,-1,+1,+2,+3> - Find out what beers are up to 4 weeks ago (-4), and up to 3 weeks ahead (+3)
#    what's <last|next> week's beerbods - Find previous / next beerbods beer
#
# Authors:
#    andersonshatch

url = "https://beerbods.andersonshatch.com/v1/"

class Config
	constructor: (@beerIndex, @responseKey) ->

lastWeek = new Config 0, "previous"
thisWeek = new Config 0, "current"
nextWeek = new Config 1, "current"

module.exports = (robot) ->
	robot.hear /(?:(?:what(?: was|(?:'|’)?s?) )?last week(?:'|’)?s beer(?:bods)?\??)|beerbods (?:prev(?:ious)?|\-([1-4])|last)\s*$/i, (message) ->
		do setEnv
		if message.match[1]
			weekIndex = parseInt(message.match[1], 10)
			weekIndex = weekIndex - 1
			lookupBeer message, new Config weekIndex, lastWeek.responseKey
		else
			lookupBeer message, lastWeek

	robot.respond /beerbods\??\s*$/i, (message) ->
		do setEnv
		lookupBeer message, thisWeek

	robot.hear /(what( is|('|’)?s?) this week('|’)?s beer(bods)?\??)|beerbods current/i, (message) ->
		do setEnv
		lookupBeer message, thisWeek

	robot.hear /(?:(?:what(?: is|(?:'|’)?s?) )?next week(?:'|’)?s beer(?:bods)?\??)|beerbods (?:next|\+([1-3]))\s*$/i, (message) ->
		do setEnv
		if message.match[1]
			weekIndex = parseInt message.match[1], 10
			lookupBeer message, new Config weekIndex, nextWeek.responseKey
		else
			lookupBeer message, nextWeek

	setEnv = () ->
		@disableSlackIdentityChange = if process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY == "true" then true else false
		@disableSlackBeerbodsPlus = if process.env.HUBOT_DISABLE_BEERBODS_PLUS == "true" then true else false


	formatMessage = (beers, pretext) ->
		attachments = []
		for beer, index in beers
			pretext = if index == 0 then pretext else "…and/or:"
			if beer.untappd.detailUrl
				footer = "Check-in on <#{beer.untappd.detailUrl}|Untappd.com> / <#{beer.untappd.mobileDeepUrl}|Untappd App>"
			else
				footer = "Search on <#{beer.untappd.searchUrl}|Untappd.com>"
			response = {
				pretext: pretext
				title: "#{beer.name} - BeerBods"
				title_link: beer.beerbodsUrl,
				image_url: beer.images[0],
				fallback: "#{pretext} #{beer.brewery.name} #{beer.name} #{beer.beerbodsUrl}"
				author_name: beer.brewery.name,
				author_link: beer.brewery.url,
				author_icon: beer.brewery.logo,
				fields: [],
				footer: footer,
				footer_icon: "https://untappd.akamaized.net/assets/favicon-16x16-v2.png"
			}

			if beer.untappd.style
				response.fields.push {
					title: "Style",
					value: beer.untappd.style,
					short: true
				}

			if beer.untappd.abv and beer.untappd.rating
				response.fields.push {
					title: "ABV / Rating",
					value: "#{beer.untappd.abv} / #{beer.untappd.rating}",
					short: true
				}

			if beer.untappd.description
				response.fields.push {
					title: "Description",
					value: beer.untappd.description
				}

			attachments.push response
		return attachments


	lookupBeer = (message, config) ->
		#Send a typing notification (slack v4 adapter only)
		robot.adapter?.client?.rtm?.sendTyping(message.message.room)

		message.http("#{url}#{config.responseKey}/#{config.beerIndex}.json").get() (error, response, body) ->
			if error
				respondWithError message
				robot.logger.error "beerbods", error
				return

			try
				data = JSON.parse body
			catch error
				respondWithError message
				robot.logger.error "beerbods badjson", error
				return

			if !data.beers or !Array.isArray(data.beers) or data.beers.length < 1
				respondWithError message
				robot.logger.error "beerbods unexpectedjson - no beers array/items"
				return

			if robot.adapterName == "slack"
				slackMessage = {
					message: message
				}
				if !@disableSlackIdentityChange
					slackMessage.username = "beerbods"
					slackMessage.icon_url = "https://beerbods.co.uk/images/favicon.ico"
					slackMessage.as_user = false
				else
					slackMessage.as_user = true

				attachments = formatMessage(data.beers, data.pretext)
				if !@disableSlackBeerbodsPlus and data.plusBeers and Array.isArray(data.plusBeers) and data.plusBeers.length > 0
					message.plusAttachments = formatMessage(data.plusBeers, data.plusPretext)

				slackMessage.attachments = attachments
				sendSlackMessage slackMessage
			else
				message.send "#{data.summary} - #{data.beerbodsUrl}"

	respondWithError = (message) ->
		message.send "Sorry, there was an error finding beers. Please check https://beerbods.co.uk"

	sendSlackMessage = (message) ->
		#For slack-adapter version 3.x:
		robot.emit "slack-attachment", message

		#For slack-adapter version 4.x:
		msg = message.message
		delete message.message
		delete message.text
		plusAttachments = msg.plusAttachments
		msg.send message, (error, slackResponse) ->
			if plusAttachments
				message.thread_ts = slackResponse[0].ts unless message.thread_ts #send plus beers threaded to the week's main beer if not already in a thread
				message.attachments = plusAttachments
				success = false
				tryCount = 0
				handle = setInterval () ->
					clearInterval handle if success or tryCount++ > 2
					msg.send message, (error, slackResponse) ->
						success = true
				, 1500
