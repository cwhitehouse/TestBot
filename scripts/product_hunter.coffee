# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
# 	For hunting for products!
#
# Configuration:
#	process.env.PRODUCT_HUNT_API_TOKEN
#	process.env.SLACK_WEB_HOOK_PRODUCT_HUNT
#
# Commands:
#	cover.bot products - Get the 5 top products on product hunt today
#	cover.bot products X - Get the X top products on product hunt today
#

require "./helpers"

module.exports = (robot) ->

	robot.respond /products( (\d+))?/i, (res) ->
		productHuntToken 	= process.env.PRODUCT_HUNT_API_TOKEN
		slackWebhook 		= process.env.SLACK_WEB_HOOK_PRODUCT_HUNT

		unless productHuntToken
			res.send "Please set the PRODUCT_HUNT_API_TOKEN environment variable"
			return

		unless slackWebhook
			res.send "Please set the SLACK_WEB_HOOK_PRODUCT_HUNT environment variable"
			return

		count = res.match[1] || 5
		unless count > 0
			res.send "Please ask for a number greater than 0..."
			return

		robot.http("https://api.producthunt.com/v1/posts")
			.headers("Authorization": "Bearer #{productHuntToken}", "Accept": "application/json", "Content-Type": "application/json", "Host": "api.producthunt.com")
			.get() (err, response, body) ->
				unless response.statusCode is 200
					res.send "Product hunt call failed with error #{response.statusCode}"
					return

				data = null
				try
					data = JSON.parse body
				catch error
					res.send "Failed to parse JSON"
					return

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
						"thumb_url"		: post.screenshot_url["300px"]
					}

				postData = JSON.stringify({
					"attachments" 	: attachments
					"channel"		: formattedChannel res
				})
				robot.http(slackWebhook)
					.post(postData) (err, response, body) ->
						unless response.statusCode is 200
							res.send "Slack web hook failed with error #{response.statusCode}"
						