class NavPoint
  
	attr_accessor :id, :playOrder, :text, :src, :navPoints, :depth
	
	def initialize(element, depth)
		parse(element, depth)
	end
	
	def to_xml
    buffer = ""
		padding = "  " * @depth
		buffer << "#{padding}<navPoint id=\"#{@id}\" playOrder=\"#{@playOrder}\">\n"
		buffer << "#{padding}  <navLabel>\n"
		buffer << "#{padding}    <text>#{@text}</text>\n"
		buffer << "#{padding}  </navLabel>\n"
		buffer << "#{padding}  <content>#{@src}</>\n"
		@navPoints.each do |point|
      buffer << point.to_xml
    end
		buffer << "#{padding}</navPoint>\n"
	end
  
	private
  
	def parse(element, depth)
		@navPoints = []
		@depth     = depth
		@id        = element.attributes["id"]
		@playOrder = element.attributes["playOrder"]
		@text      = element.elements["navLabel/text"].text
		@src       = element.elements["content"].attributes["src"]
		element.elements.each("navPoint") do |e|
			@navPoints << NavPoint.new(e, depth + 1)
		end
	end
  
end

