# Hubot Beerbods

This used to be a [beerbods](https://beerbods.co.uk) script for [Hubot](https://hubot.github.com), until beerbods closed down.
This project is now retired.


```
Joe: hubot beerbods
Hubot: This week's beer is Little Beer Corporation, Little Wild - https://beerbods.co.uk/this-weeks-beer

John: hubot what was last week's beerbods?
Hubot: Last week's beer was Thornbridge Brewery, Kill your Darlings - https://beerbods.co.uk/last-weeks-beer

Josh: hubot what's next week's beerbods?
Hubot: Next week's beer is Drygate, Axman IPA - https://beerbods.co.uk/next-weeks-beer
```
![Preview in irc/xmpp](./img/nonslack.png?raw=true)
If you're using Slack, you'll be treated to a picture of the beer(s) and a link to search for it/them on [Untappd](http://untappd.com).
![Preview in Slack](./img/slack.png?raw=true)


## Configuration

When used with Slack, the following environment variables offer configuration:

* `HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY` - The script will, by default, override the username of hubot to 'beerbods' and set the image to :beers:,
this can be disabled (mainly useful for XMPP/IRC bridges) by setting this to true
* `HUBOT_DISABLE_BEERBODS_PLUS` - The script will, by default, send the week's Beerbods Plus beer (if there is one) in a threaded reply to the main beer of the week, this can be disabled by setting this to true

Not using Slack? There's no configuration, and it's fine to ignore the npm warning:
>npm WARN hubot-beerbods@\<version\> requires a peer of hubot-slack@\<version\> but none was installed

