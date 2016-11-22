# require "kodipity/version"
require 'httparty'

module Kodipity

	@url = 'http://rpi-osmc.lan/jsonrpc'
	@headers = {"Content-Type" => 'application/json'}

	@movies = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": { "properties" : ["art", "rating", "thumbnail", "playcount", "file"], "sort": { "order": "ascending", "method": "label", "ignorearticle": true } }, "id": "libMovies"}'
	@player_active = '{"jsonrpc": "2.0", "id": 1, "method": "Player.GetProperties", "params": {"properties": ["speed"], "playerid": 1}}'
	@channels = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetChannelGroups", "params": {"channeltype" : "tv"}, "playerid": 1}}'

	def self.movies
		HTTParty.post @url, headers: @headers, body: @movies
	end

	def self.channels
		channel_groups_resp = HTTParty.post @url, headers: @headers, body: @channels
		channel_groups = channel_groups_resp['result']['channelgroups'].map{ |group| group['channelgroupid'] }
		channels = []

		channel_groups.each do |id|
			@channel_group = {jsonrpc: '2.0', id: 1, method: 'PVR.GetChannels', params: {channelgroupid: id}, playerid: 1}
			channels << HTTParty.post(@url, headers: @headers, body: @channel_group.to_json)
		end
		channels
	end

end
