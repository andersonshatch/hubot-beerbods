# Hubot Beerbods
[![Build Status](https://travis-ci.org/andersonshatch/hubot-beerbods.svg?branch=master)](https://travis-ci.org/andersonshatch/hubot-beerbods)

A [beerbods](https://beerbods.co.uk) script for [Hubot](https://hubot.github.com)

```
Joe: hubot beerbods
Hubot: This week's beer is Little Beer Corporation, Little Wild - https://beerbods.co.uk/this-weeks-beer
```
![Preview in irc/xmpp](./img/nonslack.png?raw=true)
If you're using slack, you'll be treated to a picture of the beer and a link to search for it on [Untappd](http://untappd.com).
![Preview in Slack](./img/slack.png?raw=true)


## Configuration

When used with Slack, the following environment variables offer configuration:

* `HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY` - The script will, by default, override the username of hubot to 'beerbods' and set the image to :beers:,
this can be disabled (mainly useful for XMPP/IRC bridges) by setting this to true
* `HUBOT_BEERBODS_UNTAPPD_CLIENT_ID` - optional, if set with a valid Untappd client ID and secret, the beer rating, ABV and description will be looked up from Untappd
* `HUBOT_BEERBODS_UNTAPPD_CLIENT_SECRET` - optional, see `HUBOT_BEERBODS_UNTAPPD_CLIENT_ID`

