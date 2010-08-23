class NavMap

  attr_accessor :id, :title, :creator, :depth, :docAuthor, :navPoints
	
	def initialize(entry)
    puts "parse ncx"
		doc = REXML::Document.new(entry.content)

    if doc.root.prefix != ''
      prefix = "#{doc.root.prefix}:"
    else
      prefix = ""
    end
    
    @id = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"].attributes["content"]
    @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
    # @docAuthor = doc.elements["/ncx/docAuthor/text"].text
		@navPoints = []
		doc.elements.each("/#{prefix}ncx/#{prefix}navMap/*") do |element|
			@navPoints << NavPoint.new(element, 0, prefix)
		end
    @pointArray = []
    @navPoints.each do |point|
      @pointArray += point.collect
    end
    @depth = -1
  end

  def size
    @pointArray.size
  end
  
  def navPointAtIndex(index)
    @pointArray[index]
  end
  
  def save(directory)
    File.open("#{directory}/OEBPS/toc.ncx", 'w') {|f| f.write(to_xml)}
  end
  
  def to_xml
    @map = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("toc.ncx", ofType:"erb"))).result(binding)
  end
	
end
