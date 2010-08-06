class NavMap
	
	def initialize(entry)
		@navPoints = []
		doc = REXML::Document.new(entry.content).elements.each("/ncx/navMap/*") do |element|
			@navPoints << NavPoint.new(element, 1)
		end
		self.to_xml
	end
	
	def to_xml
		puts "<?xml version=\"1.0\"?>"
		puts "<ncx version=\"2005-1\" xml:lang=\"en\" xmlns=\"http://www.daisy.org/z3986/2005/ncx/\">"
		puts ""
		puts "  <head>"
		puts "    <meta name=\"dtb:uid\" content=\"<%= @book.identifier %>\"/>"
		puts "    <meta name=\"dtb:depth\" content=\"2\"/>"
		puts "    <meta name=\"dtb:totalPageCount\" content=\"0\"/>"
		puts "    <meta name=\"dtb:maxPageNumber\" content=\"0\"/>"
		puts "  </head>"
		puts ""
		puts "  <docTitle>"
		puts "    <text><%= @book.title %></text>"
		puts "  </docTitle>"
		puts ""
		puts "  <docAuthor>"
		puts "    <text><%= @book.creator %></text>"
		puts "  </docAuthor>"
		puts "  <navMap>"
		@navPoints.each do |point|
			point.to_xml
		end
		puts "  </navMap>"
		puts "</ncx>"
	end
	
end