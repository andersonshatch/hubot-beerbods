# Hubot Beerbods

A [beerbods](https://beerbods.co.uk) script for [Hubot](https://hubot.github.com)

```
Joe: hubot beerbods
Hubot: This week's beer is Little Beer Corporation, Little Wild - https://beerbods.co.uk/this-weeks-beer
```

If you're using slack, you'll be treated to a picture of the beer too.

## Configuration

When used with Slack, the script will override the username of hubot to 'beerbods' and set the image to :beers:,
this can be disabled (mainly useful for XMPP/IRC bridges) by setting environment variable: `HUBOT_DISABLE_BEERBODS_CUSTOM_IDENTITY=true`
