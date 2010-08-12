class NavMap

  attr_accessor :id, :title, :creator, :depth, :docAuthor
	
	def initialize(entry)
		doc        = REXML::Document.new(entry.content)
    @id        = doc.elements["/ncx/head/meta[@name='dtb:uid']"].attributes["content"]
    @title     = doc.elements["/ncx/docTitle/text"].text
    # @docAuthor = doc.elements["/ncx/docAuthor/text"].text
		@navPoints = []
		doc.elements.each("/ncx/navMap/*") do |element|
			@navPoints << NavPoint.new(element, 1)
		end
    @pointArray = []
    @navPoints.each do |point|
      @pointArray += point.collect
    end
  end
  
  def depth
    @depth
  end
  
  def size
    @pointArray.size
  end
  
  def navPointAtIndex(index)
    @pointArray[index]
  end
	
	def to_xml
    buffer = ""
		buffer << "<?xml version=\"1.0\"?>\n"
    buffer << "<!DOCTYPE ncx PUBLIC \"-//NISO//DTD ncx 2005-1//EN\n"
    buffer << "  \"http://www.daisy.org/z3986/2005/ncx-2005-1.dtd\">\n"
		buffer << "<ncx version=\"2005-1\" xml:lang=\"en\" xmlns=\"http://www.daisy.org/z3986/2005/ncx/\">\n"
		buffer << "  <head>\n"
		buffer << "    <meta name=\"dtb:uid\" content=\"#{@id}\"/>\n"
		buffer << "    <meta name=\"dtb:depth\" content=\"#{@depth}\"/>\n"
		buffer << "    <meta name=\"dtb:totalPageCount\" content=\"0\"/>\n"
		buffer << "    <meta name=\"dtb:maxPageNumber\" content=\"0\"/>\n"
		buffer << "  </head>\n"
		buffer << "  <docTitle>\n"
		buffer << "    <text>#{@title}</text>\n"
		buffer << "  </docTitle>\n"
		buffer << "  <docAuthor>\n"
		buffer << "    <text>#{@docAuthor}</text>\n"
		buffer << "  </docAuthor>\n"
		buffer << "  <navMap>\n"
		@navPoints.each do |point|
			buffer << point.to_xml
		end
		buffer << "  </navMap>\n"
		buffer << "</ncx>\n"
	end
	
end
