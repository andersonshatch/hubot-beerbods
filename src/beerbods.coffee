# Description:
#   Have hubot tell you about this week's beerbods
#
# Dependencies:
#    "cheerio": "0.19.0"
#
# Configuration:
#    HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY (optional, when true disables overriding username and image with slack adapter)
#
# Commands:
#    hubot beerbods - Find out what beer is this week's beerbods
#
# Authors:
#    andersonshatch

cheerio = require "cheerio"

disableSlackIdentityChange = if process.env.HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY == "true" then true else false

module.exports = (robot) ->
	robot.respond /(what('|’)?s? this week('|’)?s )?beerbods\??/i, (message) ->
		url = "https://beerbods.co.uk"
		message.http(url).get() (error, response, body) ->
			if error
				message.send "Sorry, there was an error finding this week's beer. Check #{url}"
				robot.logger.error "beerbods", error
				return
			$ = cheerio.load body
			div = $('div.beerofweek-container')
			beerDelta = 0
			beerTitle = $('h3', div).eq(beerDelta).text()
			text = "This week's beer is " + beerTitle + " - #{url}" + $('a', div).eq(beerDelta).attr("href")
			if robot.adapterName == "slack"
				robot.emit "slack-attachment", {
					username: "beerbods" unless disableSlackIdentityChange,
					icon_emoji: ":beers:" unless disableSlackIdentityChange,
					message: message,
					attachments: [{
						pretext: "This week's beer:",
						title: beerTitle,
						title_link: url + $('a', div).eq(beerDelta).attr("href"),
						image_url: url + $('img', div).eq(beerDelta).attr("src"),
						fallback: text
						fields: [{
							title: "Untappd",
							value: "<https://untappd.com/search?q=" + encodeURIComponent(beerTitle) + "|Search on Untappd>"
							short: true
						}]
					}]
				}
			else
				message.send text

