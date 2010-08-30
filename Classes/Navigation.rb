class Navigation

  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book, prefix='')
    doc = book.spine.ncxDoc

    prefix = "#{doc.root.prefix}:" if doc.root.prefix != ''

    @id = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"].attributes["content"]
    @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
    # @docAuthor = doc.elements["/ncx/docAuthor/text"].text

    @root = Point.new
    doc.elements.each("/#{prefix}ncx/#{prefix}navMap/*") do |element|
      @root << Point.new(book.container.root, element, prefix)
    end
  end

  def [](index)
    @root.traverse(index).first
  end

  def save(directory)
    File.open("#{directory}/OEBPS/toc.ncx", 'w') {|f| f.write(to_xml)}
  end

  def to_xml
    @navigation = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("toc.ncx", ofType:"erb"))).result(binding)
  end

end
