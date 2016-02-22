# Description:
#   Have hubot tell you about this week's beerbods
#
# Dependencies:
#    "cheerio": "0.19.0"
#    "humanize": "0.0.9"
#    "pluralize": "1.2.1"
#
# Configuration:
#    HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY (optional, when true disables overriding username and image with slack adapter)
#    HUBOT_BEERBODS_UNTAPPD_CLIENT_ID (optional, Untappd API will be used to show beer rating -- slack adapter only)
#    HUBOT_BEERBODS_UNTAPPD_CLIENT_SECRET (optional, see HUBOT_BEERBODS_UNTAPPD_CLIENT_ID)
#
# Commands:
#    hubot beerbods - Find out what beer is this week's beerbods
#
# Authors:
#    andersonshatch

cheerio = require "cheerio"
humanize = require "humanize"
pluralize = require "pluralize"

url = "https://beerbods.co.uk"
untappdApiRoot = "https://api.untappd.com/v4"

module.exports = (robot) ->
	robot.respond /(what('|’)?s? this week('|’)?s )?beerbods\??/i, (message) ->

		disableSlackIdentityChange = if process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY == "true" then true else false
		untappdClientId = process.env.HUBOT_BEERBODS_UNTAPPD_CLIENT_ID
		untappdClientSecret = process.env.HUBOT_BEERBODS_UNTAPPD_CLIENT_SECRET

		message.http(url).get() (error, response, body) ->
			if error
				respondWithError message
				robot.logger.error "beerbods", error
				return
			$ = cheerio.load body
			div = $('div.beerofweek-container')
			beerDelta = 0
			beerTitle = $('h3', div).eq(beerDelta).text()
			beerHref = $('a', div).eq(beerDelta).attr('href')

			if !beerTitle or !beerHref
				respondWithError message
				robot.logger.error "beerbods beer not found - page layout unexpected"
				return

			beerUrl = url + beerHref

			text = "This week's beer is #{beerTitle} - #{beerUrl}"

			if robot.adapterName == "slack"
				slackMessage = {
					username: "beerbods" unless disableSlackIdentityChange,
					icon_emoji: ":beers:" unless disableSlackIdentityChange,
					message: message,
					attachments: [{
						pretext: "This week's beer:",
						title: beerTitle,
						title_link: beerUrl,
						image_url: url + $('img', div).eq(beerDelta).attr("src"),
						fallback: text
						fields: [{
							title: "Untappd",
							value: "<https://untappd.com/search?q=" + encodeURIComponent(beerTitle) + "|Search on Untappd>"
							short: true
						}]
					}]
				}
				if untappdClientId and untappdClientSecret
					searchBeerOnUntappd beerTitle, slackMessage, {id: untappdClientId, secret: untappdClientSecret, apiRoot: untappdApiRoot}
				else
					sendSlackMessage slackMessage
			else
				message.send text

	respondWithError = (message) ->
		message.send "Sorry, there was an error finding this week's beer. Check #{url}"

	sendSlackMessage = (message) ->
		robot.emit "slack-attachment", message

	searchBeerOnUntappd = (beerTitle, slackMessage, untappd) ->
		robot.http("#{untappd.apiRoot}/search/beer?q=#{encodeURIComponent beerTitle}&limit=1&client_id=#{untappd.id}&client_secret=#{untappd.secret}")
			.get() (err, res, body) ->
				if err
					robot.logger.error "beerbods-untappd-search", err
					sendSlackMessage slackMessage
					return
				data = JSON.parse body
				if !data or data.response.found != 1
					#Unsure which to pick, so bail and leave the search link
					sendSlackMessage slackMessage
					return

				untappdBeerId = data.response.beers.items[0].beer.bid
				lookupBeerOnUntappd untappdBeerId, slackMessage, untappd

	lookupBeerOnUntappd = (untappdBeerId, slackMessage, untappd) ->
		robot.http("#{untappd.apiRoot}/beer/info/#{untappdBeerId}?compact=true&client_id=#{untappd.id}&client_secret=#{untappd.secret}")
			.get() (error, response, body) ->
				if error or response.statusCode != 200
					robot.logger.error "beerbods-untappd-beer-bid-#{untappdBeerId}", error ||= response.statusCode + body
					sendSlackMessage slackMessage
					return

				data = JSON.parse body
				if !data
					robot.logger.error "beerbods-untappd-beer-baddata-bid-#{untappdBeerId}", body
					sendSlackMessage slackMessage
					return

				beer = data.response.beer
				slackMessage.attachments[0].fields[0].value = "<https://untappd.com/b/#{beer.beer_slug}/#{beer.bid}|View on Untappd>"
				slackMessage.attachments[0].fields.push {
					title: "ABV / Rating",
					value: "#{beer.beer_abv ||= 'N/A'}% / #{humanize.numberFormat beer.rating_score} avg, #{humanize.numberFormat beer.rating_count, 0} #{pluralize 'rating', beer.rating_count}"
					short: true
				}
				slackMessage.attachments[0].fields.push {
					title: "Description"
					value: beer.beer_description
				} if beer.beer_description and beer.beer_description != ""

				sendSlackMessage slackMessage

