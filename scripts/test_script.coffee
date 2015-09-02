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
#	test_bot products - Get the 5 top products on product hunt today
#	test_bot products X - Get the X top products on product hunt today
#

formattedChannel = (res) ->
	if res.message.room == res.message.user.name
		"@#{res.message.room}"
	else
		"##{res.message.room}"

module.exports = (robot) ->

	robot.respond /test/i, (res) ->
		res.send "Test complete\nchannel = #{formattedChannel res}\nuser = #{res.message.user.name}"

	robot.respond /products( (\d+))?/i, (res) ->
		productHuntToken = process.env.PRODUCT_HUNT_API_TOKEN
		slackWebhook = process.env.SLACK_WEB_HOOK

		unless productHuntToken
			res.send "Please set the PRODUCT_HUNT_API_TOKEN environment variable"
			return

		unless slackWebhook
			res.send "Please set the SLACK_WEB_HOOK environment variable"
			return

		count = res.match[1] || 5
		unless count > 0
			res.send "Please ask for a number greater than 0..."
			return

		robot.http("https://api.producthunt.com/v1/posts")
			.headers("Authorization": "Bearer #{productHuntToken}", "Accept": "application/json", "Content-Type": "application/json", "Host": "api.producthunt.com")
			.get() (err, response, body) ->
				switch response.statusCode
					when 200
						data = null
						try
							data = JSON.parse body

							attachments = []

							for post in data.posts[..(count-1)]
								attachments.push {
									"fallback"		: "#{post.name}\n#{post.tagline}\n#{post.discussion_url}"
									"color"			: "#da552f"
									"author_name"	: post.user.name
									"author_link"	: post.user.profile_url
									"author_icon"	: post.user.image_url["32px"]
									"title"			: post.name
									"title_link"	: post.discussion_url
									"text"			: post.tagline
									"image_url"		: post.screenshot_url["300px"]
								}

							postData = JSON.stringify({
								"attachments" 	: attachments
								"channel"		: formattedChannel res
							})
							robot.http(slackWebhook)
									.post(postData) (err, response, body) ->
										switch response.statusCode
											when 200
												return
											else
												res.send "Slack web hook failed with error #{response.statusCode}"

						catch error
							res.send "Failed to parse JSON"
					else
						res.send "Product hunt call failed with error #{response.statusCode}"


				
				