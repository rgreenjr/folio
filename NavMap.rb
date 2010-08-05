class NavMap
	
	def initialize(xml_str)
		@navPoints = []
		parse(xml_str)
		puts self
	end
	
	def size
		@navPoints.size
	end
	
	def navPointAt(index)
		@navPoints[index]
	end
	
	def to_s
		buffer = ""
		@navPoints.each do |point|
			buffer << point.to_s
			buffer << "\n"
		end
		buffer
	end
	
	private
	
	def parse(xml_str)
		doc = REXML::Document.new(xml_str)
		doc.elements.each("/ncx/navMap/*") do |element|
			point = NavPoint.new(element)
			@navPoints << point
			#p point
		end
	end

end