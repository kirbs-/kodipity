require 'httparty'
require 'json'

module Kodipity


	class PVRRecording
		attr_accessor :title, :id, :plot, :json, :url, :plot_outline, :file, :channel, :run_time, :genre, :play_count, :start_time

		# json = {jsonrpc: '2.0', id: 1, method: 'PVR.GetRecordingDetails', params: { properties: ['title','plot','plotoutline','file'] }}

		def initialize(recording_id, fetch_data = false)
			@title = title
			@id = recording_id
			@plot = plot
			@json = {jsonrpc: '2.0', id: 1, method: 'PVR.GetRecordingDetails', params: { properties: ['title','plot','plotoutline','file', 'channel','runtime', 'genre', 'playcount','starttime'] } }
			@url = 'http://rpi-osmc.lan/jsonrpc'
			# @url = 'http://127.0.0.1:8080/jsonrpc'
			@headers = {"Content-Type" => 'application/json'}
			@json[:params][:recordingid] = @id
			metadata if fetch_data
		end

		def metadata
			response = HTTParty.post(@url, headers: @headers, body: @json.to_json)['result']['recordingdetails']
			@title = response['title']
			@plot_outline = response['plotoutline']
			@file = response['file']
			@channel = response['channel']
			@run_time = response['runtime']
			@genre = response['genre']
			@play_count = response['playcount']
			@start_time = response['starttime']
			self
		end

		def play
			@json[:method] = 'Player.Open'
			@json[:params] = {item: {recordingid: @id}}
			HTTParty.post(@url, headers: @headers, body: @json.to_json)
		end
	end

	class Channel
		attr_accessor :name, :channel_id

		def initialize(name, channel_id)
			@name = name
			@channel_id = channel_id
			@url = 'http://rpi-osmc.lan/jsonrpc'
			@headers = {"Content-Type" => 'application/json'}
			@json = {jsonrpc: '2.0', id: 1, method: 'PVR.GetRecordingDetails', params: { properties: ['title','plot','plotoutline','file', 'channel','runtime', 'genre', 'playcount','starttime'] } }
		end

		def play
			@json[:method] = 'Player.Open'
			@json[:params] = { item: { channelid: @channel_id } }
			HTTParty.post @url, headers: @headers, body: @json.to_json
		end
	end

end