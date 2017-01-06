# require "kodipity/version"
require 'httparty'
require 'kodipity/models'
require 'uri'
require 'byebug'

module Kodipity
	class Kodi
		attr_reader :url, :headers, :_movies, :_channels, :_recordings, :_player_active, :_player_pause
		attr_reader :media

		def initialize(url)
			@url = url
			@media = {movies: {}, recordings: [], tv_shows: {}, channels: {}}
			@headers = {"Content-Type" => 'application/json'}

			@_movies = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": { "properties" : ["art", "rating", "thumbnail", "playcount", "file"], "sort": { "order": "ascending", "method": "label", "ignorearticle": true } }, "id": "libMovies"}'
			@_player_active = '{"jsonrpc": "2.0", "id": 1, "method": "Player.GetProperties", "params": {"properties": ["speed"], "playerid": 1}}'
			@_channels = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetChannelGroups", "params": {"channeltype" : "tv"}}}'
			@_recordings = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetRecordings"}}'
			@_player_pause = '{"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 1 }, "id": 1}'
		end

		# @url = 'http://rpi-osmc.lan/jsonrpc'
		# @url = 'http://127.0.0.1:8080/jsonrpc'
		# headers = {"Content-Type" => 'application/json'}

		# _movies = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": { "properties" : ["art", "rating", "thumbnail", "playcount", "file"], "sort": { "order": "ascending", "method": "label", "ignorearticle": true } }, "id": "libMovies"}'
		# _player_active = '{"jsonrpc": "2.0", "id": 1, "method": "Player.GetProperties", "params": {"properties": ["speed"], "playerid": 1}}'
		# _channels = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetChannelGroups", "params": {"channeltype" : "tv"}}}'
		# _recordings = '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetRecordings"}}'
		# _player_pause = '{"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 1 }, "id": 1}'

		def movies
			return media[:movies] unless media[:movies].empty?
			HTTParty.post(url, headers: headers, body: _movies)['result']['movies'].each do |movie|
				media[:movies][movie['label']] = movie['movieid']
			end
			media[:movies]
		end

		def channels
			return media[:channels] unless media[:channels].empty?

			channel_groups_resp = HTTParty.post url, headers: headers, body: _channels
			channel_groups = channel_groups_resp['result']['channelgroups'].map{ |group| group['channelgroupid'] }

			channel_groups.each do |id|
				channel_group = {jsonrpc: '2.0', id: 1, method: 'PVR.GetChannels', params: {channelgroupid: id}, playerid: 1}
				HTTParty.post(@url, headers: @headers, body: channel_group.to_json)['result']['channels'].each do |channel|
					media[:channels][channel['label']] = channel['channelid']
				end
			end
			media[:channels]
		end

		def recordings(metadata = true)
			return media[:recordings] unless media[:recordings].empty?
			HTTParty.post(url, headers: headers, body: _recordings)['result']['recordings'].each do |recording|
				# puts recording.to_s
				media[:recordings] << Kodipity::PVRRecording.new(recording['recordingid'], metadata)
			end
			media[:recordings]
		end

		def rec
			HTTParty.post(url, headers: headers, body: '{"jsonrpc": "2.0", "id": 1, "method": "PVR.GetRecordingDetails", "params": {"recordingid" : 122, "properties": ["title", "plot", "plotoutline", "file"]}, "playerid": 1}')
		end

		def docs(param)
			HTTParty.post(url, headers: headers, body: '{ "jsonrpc": "2.0", "method": "JSONRPC.Introspect", "params": { "filter": { "id": "Player.Open", "type": "method" } }, "id": 1 }')
		end

		def playing?
			Kodipity.active_players.size > 0
		end

		def active_players
			out = {}
			HTTParty.post(url, headers: headers, body: '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 1}')['result'].each do |player|
				out = player.merge(out)
			end
		end

		def play(file)
			file_url = URI.encode(file)
			HTTParty.post(url, headers: headers, body: '{"jsonrpc": "2.0", "method": "Player.Open", "params": { "item": {"recordingid": "pvr://recordings/active///The%20Goldbergs%20The%20Greatest%20Musical%20Ever%20Written,%20TV%20(7.1%20WJLADT),%2020161201_010000.pvr"} }, id": 1}')
		end

		def pause
			HTTParty.post(url, headers: headers, body: _player_pause)
		end

		def play_next_recording(tv_show)
			recs = recordings.select{ |rec| rec.title.include? tv_show }
			recs.sort_by!{ |rec| rec.start_time}

			watched_episode = false

			recs.each do |rec|
				if watched_episode
					# rec.play 
					return rec
				end
				watched_episode = true if rec.play_count > 0
			end

			# recs[0].play
			recs[0]
		end

		

	end
end
