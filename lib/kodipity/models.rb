
module Kodipity

	class PVRRecording
		attr_accessor :title, :id, :plot

		def initialize(title, recording_id, plot = "")
			self.title = title
			self.id = recording_id
			self.plot = plot
		end
	end

end