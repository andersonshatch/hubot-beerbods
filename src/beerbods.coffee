# Description:
#   Have hubot tell you about this week's beerbods
#
# Dependencies:
#    "cheerio": "0.19.0"
#
# Configuration:
#    None
#
# Commands:
#    hubot beerbods - Find out what beer is this week's beerbods
#
# Authors:
#    andersonshatch

cheerio = require "cheerio"

module.exports = (robot) ->
	robot.respond /(what'?s? this week'?s )?beerbods\??/i, (message) ->
		url = "https://beerbods.co.uk"
		message.http(url).get() (error, response, body) ->
			if error
				message.send "Sorry, there was an error finding this week's beer. Check #{url}"
				robot.logger.error "beerbods", error
				return
			$ = cheerio.load body
			div = $('div.beerofweek-container')
			text = "This week's beer is " + $('h3', div).eq(0).text() + " - #{url}" + $('a', div).eq(0).attr("href")
			if robot.adapterName == "slack"
				robot.emit "slack-attachment", {
					message: message,
					attachments: [{
						pretext: "This week's beer:",
						title: $('h3', div).eq(0).text(),
						title_link: url + $('a', div).eq(0).attr("href"),
						image_url: url + $('img', div).eq(0).attr("src"),
						fallback: text
					}]
				}
			else
				message.send text

