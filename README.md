# Hubot Beerbods
[![Build Status](https://travis-ci.org/andersonshatch/hubot-beerbods.svg?branch=master)](https://travis-ci.org/andersonshatch/hubot-beerbods)

A [beerbods](https://beerbods.co.uk) script for [Hubot](https://hubot.github.com)

```
Joe: hubot beerbods
Hubot: This week's beer is Little Beer Corporation, Little Wild - https://beerbods.co.uk/this-weeks-beer

John: hubot what was last week's beerbods?
Hubot: Last week's beer was Thornbridge Brewery, Kill your Darlings - https://beerbods.co.uk/last-weeks-beer

Josh: hubot what's next week's beerbods?
Hubot: Next week's beer is Drygate, Axman IPA - https://beerbods.co.uk/next-weeks-beer
```
![Preview in irc/xmpp](./img/nonslack.png?raw=true)
If you're using Slack, you'll be treated to a picture of the beer and a link to search for it on [Untappd](http://untappd.com).
Providing Untappd API keys (with configuration shown below) will enable looking up more info about the beer from Untappd. (If more than one match is found for the Beerbods name on Untappd, the link to search will be sent instead)
![Preview in Slack](./img/slack.png?raw=true)


## Configuration

When used with Slack, the following environment variables offer configuration:

* `HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY` - The script will, by default, override the username of hubot to 'beerbods' and set the image to :beers:,
this can be disabled (mainly useful for XMPP/IRC bridges) by setting this to true
* `HUBOT_BEERBODS_UNTAPPD_CLIENT_ID` - optional, if set with a valid Untappd client ID and secret, the beer rating, ABV and description will be looked up from Untappd
* `HUBOT_BEERBODS_UNTAPPD_CLIENT_SECRET` - optional, see `HUBOT_BEERBODS_UNTAPPD_CLIENT_ID`

Not using Slack? There's no configuration, and it's fine to ignore the npm warning:
>npm WARN hubot-beerbods@<version> requires a peer of hubot-slack@<version> but none was installed

