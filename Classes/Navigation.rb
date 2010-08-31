class Navigation

  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book)
    doc = book.spine.ncxDoc
        
    prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''

    @id = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"].attributes["content"]
    @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
    # @docAuthor = doc.elements["/ncx/docAuthor/text"].text

    @root = Point.new
    @root.expanded = true
    
    point_stack = [@root]
    xml_stack = [doc.elements["/#{prefix}ncx/#{prefix}navMap"]]
    while point_stack.size > 0
      parent = point_stack.shift
      element = xml_stack.shift
      element.elements.each_with_index("#{prefix}navPoint") do |e, i|

        uri = URI.parse(e.elements["#{prefix}content"].attributes["src"])
        item = book.manifest.itemWithHref(uri.path)
        raise "Navigation point source is missing: #{uri.path}" unless item

        child           = Point.new
        child.id        = e.attributes["id"]
        child.playOrder = e.attributes["playOrder"]
        child.text      = e.elements["#{prefix}navLabel/#{prefix}text"].text
        child.item      = item
        child.fragment  = uri.fragment

        parent << child
        point_stack.insert(i, child)
        xml_stack.insert(i, e)
      end
    end

  end

  def depth
    @root.depth - 1
  end

  def [](index)
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      return item if index == -1
      if item.expanded
        item.each_with_index {|child, i| stack.insert(i, child)}
      end
      index -= 1
    end
  end

  def save(directory)
    File.open("#{directory}/OEBPS/toc.ncx", 'w') {|f| f.write(to_xml)}
    system("mate #{directory}/OEBPS/toc.ncx")
  end

  def to_xml
    @navigation = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("toc.ncx", ofType:"erb"))).result(binding)
  end

end
