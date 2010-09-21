class Navigation

  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book)
    doc = REXML::Document.new(book.manifest.ncx.content)    
        
    prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''

    @id = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"].attributes["content"]
    @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
    # @docAuthor = doc.elements["/ncx/docAuthor/text"].text

    @root = Point.new(true)
    
    point_stack = [@root]
    xml_stack = [doc.elements["/#{prefix}ncx/#{prefix}navMap"]]
    while point_stack.size > 0
      parent = point_stack.shift
      element = xml_stack.shift
      element.elements.each_with_index("#{prefix}navPoint") do |e, i|

        uri = URI.parse(e.elements["#{prefix}content"].attributes["src"])
        item = book.manifest.itemWithHref(uri.path)
        raise "Navigation point is missing: #{uri.path}" unless item

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

  def each(includeCollapsed=false, &block)
    stack = [@root]
    while stack.size > 0
      point = stack.shift
      yield(point)
      if point.expanded? || includeCollapsed
        point.each_with_index {|child, i| stack.insert(i, child)}
      end
    end
  end
  
  def each_with_index(includeCollapsed=false, &block)
    index = 0
    each(includeCollapsed) do |point|
      yield(point, index)
      index += 1
    end
  end

  def [](index)
    each_with_index do |point, idx|
      return point if index - idx == -1
    end
  end
  
  def delete(point)
    each do |pt|
      index = pt.index(point)
      return pt.delete_at(index) if index
    end
  end
  
  def save(directory)
    File.open("#{directory}/toc.ncx", 'w') {|f| f.write(to_xml)}
  end

  def to_xml
    @navigation = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("toc.ncx", ofType:"erb"))).result(binding)
  end

end
