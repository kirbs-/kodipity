# require "kodipity/version"
require 'httparty'
require 'kodipity/models'

module Kodipity

	@url = 'http://rpi-osmc.lan/jsonrpc'
	@headers = {"Content-Type" => 'application/json'}

	@movies = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": { "properties" : ["art", "rating", "thumbnail", "playcount", "file"], "sort": { "order": "ascending", "method": "label", "ignorearticle": true } }, "id": "libMovies"}'
	@player_active = '{"jsonrpc": "2.0", "id": 1, "method": "Player.GetProperties", "params": {"properties": ["speed"], "playerid": 1}}'
	@channels = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetChannelGroups", "params": {"channeltype" : "tv"}, "playerid": 1}}'
	@recordings = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetRecordings", "playerid": 1}}'

	def self.movies
		movies = {}
		HTTParty.post(@url, headers: @headers, body: @movies)['result']['movies'].each do |movie|
			movies[movie['label']] = movie['movieid']
		end
		movies
	end

	def self.channels
		channel_groups_resp = HTTParty.post @url, headers: @headers, body: @channels
		channel_groups = channel_groups_resp['result']['channelgroups'].map{ |group| group['channelgroupid'] }
		channels = {}

		channel_groups.each do |id|
			channel_group = {jsonrpc: '2.0', id: 1, method: 'PVR.GetChannels', params: {channelgroupid: id}, playerid: 1}
			HTTParty.post(@url, headers: @headers, body: channel_group.to_json)['result']['channels'].each do |channel|
				channels[channel['label']] = channel['channelid']
			end
		end
		channels
	end

	def self.recordings
		recordings = []
		HTTParty.post(@url, headers: @headers, body: @recordings)['result']['recordings'].each do |recording|
			recordings << Kodipity::PVRRecording.new(recording['label'], recording['recordingid'])
		end
		recordings
	end

	def self.rec
		HTTParty.post(@url, headers: @headers, body: '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetRecordingDetails", "params": {"recordingid" : 362, "properties": ["title"]}, "playerid": 1}')
	end

	def self.doc(param)
		HTTParty.post(@url, headers: @headers, body: '{ "jsonrpc": "2.0", "method": "JSONRPC.Introspect", "params": { "filter": { "id": "PVR.GetRecordingDetails", "type": "method" } }, "id": 1 }')
	end

end
