# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
#
# Commands:
# 	test_bot test - Test it.
#	test_bot products - Get the top posts on product hunt today
#

module.exports = (robot) ->

	robot.respond /test/i, (res) ->
		res.send "Test complete"

	robot.respond /products/i, (res) ->
		res.send "Fetching from Product Hunt"

		productHuntToken = process.env.PRODUCT_HUNT_API_TOKEN
		unless productHuntToken
			res.send "Please set the PRODUCT_HUNT_API_TOKEN environment variable"
			return

		robot.http("https://api.producthunt.com/v1/posts")
			.headers("Authorization": "Bearer #{productHuntToken}", "Accept": "application/json", "Content-Type": "application/json", "Host": "api.producthunt.com")
			.get() (err, response, body) ->
				switch response.statusCode
					when 201
						data = null
						try
							data = JSON.parse body
						catch error
							res.send "Failed to parse JSON"
							return

						res.send "#{body}"
					else
						ms.send "Call failed with code #{response.statusCode}"


				
				