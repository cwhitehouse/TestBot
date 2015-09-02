# Description:
#   Helper methods!
#

module.exports = ->

	@formattedChannel = (res) ->
		if res.message.room == res.message.user.name
			"@#{res.message.room}"
		else
			"##{res.message.room}"

	@repeat = (str, n) ->
		res = ""
		while n > 0
			res += str if n & 1
			n >>>= 1
			str += str
		res
	