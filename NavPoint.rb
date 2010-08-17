class NavPoint
  
	attr_accessor :id, :playOrder, :text, :src, :navPoints, :depth
	
	def initialize(element, depth, prefix)
		parse(element, depth, prefix)
	end
  
  def collect
    array = [self]
    navPoints.each do |point|
      array += point.collect
    end
    array
  end
  
  def indentedText
		"  " * @depth + @text
  end
  
	def to_xml
    buffer = ""
		padding = "  " * @depth
		buffer << "#{padding}<navPoint id=\"#{@id}\" playOrder=\"#{@playOrder}\">\n"
		buffer << "#{padding}  <navLabel>\n"
		buffer << "#{padding}    <text>#{@text}</text>\n"
		buffer << "#{padding}  </navLabel>\n"
		buffer << "#{padding}  <content src=\"#{@src}\"/>\n"
		@navPoints.each do |point|
      buffer << point.to_xml
    end
		buffer << "#{padding}</navPoint>\n"
	end
  
	private
  
	def parse(element, depth, prefix)
		@navPoints = []
		@depth     = depth
		@id        = element.attributes["id"]
		@playOrder = element.attributes["playOrder"]
		@text      = element.elements["#{prefix}navLabel/#{prefix}text"].text
		@src       = element.elements["#{prefix}content"].attributes["src"]
		element.elements.each("#{prefix}navPoint") do |e|
			@navPoints << NavPoint.new(e, depth + 1, prefix)
		end
	end
  
end

