class NavPoint

	attr_accessor :id, :playOrder, :text, :src, :navPoints
	
	def initialize(xml_element)
		@navPoints = []
		@id        = xml_element.attributes["id"]
		@playOrder = xml_element.attributes["playOrder"]
		@text      = xml_element.elements["navLabel/text"].text
		@src       = xml_element.elements["content"].attributes["src"]
		parse(xml_element)
	end
	
	def size
		@navPoints.size
	end
	
	def navPointAt(index)
		@navPoints[index]
	end

	def to_s
		buffer = @text
		@navPoints.each do |point|
			buffer << point.to_s
			buffer << "\n"
		end
		buffer
	end
	
	private
	
	def parse(xml_element)
		xml_element.elements.each("navPoint/navPoint") do |element|
			point = NavPoint.new(element)
			@navPoints << point
			#p point
		end
	end

end

