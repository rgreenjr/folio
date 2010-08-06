class NavPoint
  
	attr_accessor :id, :playOrder, :text, :src, :navPoints, :level
	
	def initialize(element, level)
		parse(element, level)
	end
	
	def to_xml
		padding = "  " * @level
		puts "#{padding}<navPoint id=\"#{@id}\" playOrder=\"#{@playOrder}\">"
		puts "#{padding}  <navLabel>"
		puts "#{padding}    <text>#{@text}</text>"
		puts "#{padding}  </navLabel>"
		puts "#{padding}  <content>#{@src}</>"
		@navPoints.each {|point| point.to_xml}
		puts "#{padding}</navPoint>"
	end
  
	private
  
	def parse(element, level)
		@navPoints = []
		@level     = level
		@id        = element.attributes["id"]
		@playOrder = element.attributes["playOrder"]
		@text      = element.elements["navLabel/text"].text
		@src       = element.elements["content"].attributes["src"]
		#puts @playOrder + ' => ' * level + @text
		element.elements.each("navPoint") do |e|
			@navPoints << NavPoint.new(e, level + 1)
		end
	end
  
end

