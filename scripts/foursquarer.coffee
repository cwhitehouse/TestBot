# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
# 	For getting restaurant info!
#
# Configuration:
#	process.env.FOURSQUARE_CLIENT_ID
#	process.env.FOURSQUARE_CLIENT_SECRET
#	process.env.SLACK_WEB_HOOK_FOURSQUARE
#
# Commands:
#	cover.bot fsq NYC <query> - Get info about the restaurant near NYC best matching <query>
#	cover.bot fsq SF <query> - Get info about the restaurant near SF best matching <query>
#	cover.bot fsq LA <query> - Get info about the restaurant near LA best matching <query>
#	cover.bot fsq LON <query> - Get info about the restaurant near LON best matching <query>
#

require "./helpers"

module.exports = (robot) ->

	robot.respond /fsq NYC (.*)/i, (res) ->
		query = res.match[1]
		searchRestaurant(robot, res, query, 40.755574, -73.979252)

	robot.respond /fsq SF (.*)/i, (res) ->
		query = res.match[1]
		searchRestaurant(robot, res, query, 37.777410, -122.458371)

	robot.respond /fsq LA (.*)/i, (res) ->
		query = res.match[1]
		searchRestaurant(robot, res, query, 34.057381, -118.334281)

	robot.respond /fsq LON (.*)/i, (res) ->
		query = res.match[1]
		searchRestaurant(robot, res, query, 51.528428, -0.196012)


searchRestaurant = (robot, res, query, lat, lon) ->
	foursquareClientID 		= process.env.FOURSQUARE_CLIENT_ID
	foursquareClientSecret 	= process.env.FOURSQUARE_CLIENT_SECRET
	slackWebhook 			= process.env.SLACK_WEB_HOOK_FOURSQUARE

	unless foursquareClientID
		res.send "Please set the FOURSQUARE_CLIENT_ID environment variable"
		return

	unless foursquareClientSecret
		res.send "Please set the FOURSQUARE_CLIENT_SECRET environment variable"
		return

	unless slackWebhook
		res.send "Please set the SLACK_WEB_HOOK_FOURSQUARE environment variable"
		return

	robot.http("https://api.foursquare.com/v2/venues/search?ll=#{lat},#{lon}&query=#{query}&client_id=#{foursquareClientID}&client_secret=#{foursquareClientSecret}&v=20150902&limit=1")
		.get() (err, response, body) ->
			unless response.statusCode is 200
				res.send "Foursquare call failed with error : #{body}"
				return

			data = null
			try
				data = JSON.parse body
			catch error
				res.send "Failed to parse JSON : #{error.message}"
				return

			unless data.response.venues[0]?
				res.send "Couldn't find any restaurants that match #{query}"
				return

			bestMatchID = data.response.venues[0].id
			robot.http("https://api.foursquare.com/v2/venues/#{bestMatchID}?client_id=#{foursquareClientID}&client_secret=#{foursquareClientSecret}&v=20150902&limit=1")
				.get() (err, response, body) ->
					unless response.statusCode is 200
						res.send "Foursquare call failed with error : #{body}"
						return

					data = null
					try
						data = JSON.parse body
					catch error
						res.send "Failed to parse JSON : #{error.message}"
						return

					venue = data.response.venue
					fields = []

					if venue.location?
						fields.push {
							"title"			: "Address"
							"value"			: venue.location.formattedAddress
						}

					if venue.rating?
						fields.push {
							"title"			: "Rating"
							"value"			: venue.rating
							"short"			: true
						}

					if venue.price?
						fields.push {
							"title"			: "Price"
							"value"			: "#{repeat(venue.price.currency, venue.price.tier)} - #{venue.price.message}"
							"short"			: true
						}

					if venue.hours?
						fields.push {
							"title"			: "Hours"
							"value"			: venue.hours.status
							"short"			: true
						}

					if venue.categories?
						categories = venue.categories.map (c) -> c.shortName
						fields.push {
							"title"			: "Categories"
							"value"			: categories.join(", ")
							"short"			: true
						}

					if venue.menu?
						fields.push {
							"title"			: "Menu"
							"value"			: venue.menu.url
						}

					if venue.phrases?
						phrases = venue.phrases.map (p) -> p.phrase
						fields.push {
							"title"			: "People Mention"
							"value"			: phrases.join(", ")
						}

					if venue.tips?
						tips = venue.tips.groups[0].items[..2].map (t) -> "#{t.text} - #{t.user.firstName} #{t.user.lastName || ""}"
						fields.push {
							"title"			: "Tips"
							"value"			: tips.join("\n\n")
						}

					if venue.photos?
						firstPhoto = venue.photos.groups[0].items[0]
						attachments = [{
							"fallback"		: "#{venue.name}\n#{venue.description || "No description"}"
							"color"			: "#0732a2"
							"title"			: venue.name
							"title_link"	: venue.canonicalUrl
							"fields"		: fields
							"text"			: "#{venue.url}\n#{venue.description || ""}"
							"thumb_url"		: "#{firstPhoto.prefix}100x100#{firstPhoto.suffix}"
						}]

					postData = JSON.stringify({
						"attachments" 	: attachments
						"channel"		: formattedChannel res
					})
					robot.http(slackWebhook)
						.post(postData) (err, response, body) ->
							unless response.statusCode is 200
								res.send "Slack web hook failed with error #{response.statusCode}"

			
