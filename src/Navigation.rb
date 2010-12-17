class Navigation

  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book)
    @hash  = {}
    
    doc = REXML::Document.new(book.manifest.ncx.content)
    
    @ncx_name = book.manifest.ncx.name
        
    prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''

    @id = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"].attributes["content"]
    @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
    
    if doc.elements["/ncx/docAuthor/text"]
      @docAuthor = doc.elements["/ncx/docAuthor/text"].text
    end

    @root = Point.new

    point_stack = [@root]
    xml_stack = [doc.elements["/#{prefix}ncx/#{prefix}navMap"]]
    while point_stack.size > 0
      parent = point_stack.shift
      element = xml_stack.shift
      element.elements.each_with_index("#{prefix}navPoint") do |e, i|
        href, fragment = e.elements["#{prefix}content"].attributes["src"].split('#')

        item = book.manifest.itemWithHref(href)
        raise "Navigation point is missing: src=#{href}" unless item
                
        childPoint           = Point.new(parent)
        childPoint.id        = e.attributes["id"]
        childPoint.playOrder = e.attributes["playOrder"]
        childPoint.text      = e.elements["#{prefix}navLabel/#{prefix}text"].text
        childPoint.item      = item
        childPoint.fragment  = fragment

        hashPoint(childPoint)
        # @hash[childPoint.id] = childPoint
        
        point_stack.insert(i, childPoint)
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
        point.each_with_index {|childPoint, i| stack.insert(i, childPoint)}
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
  
  def insert(point, index, parent)
    hashPoint(point) 
    parent.insert(index, point)
  end
  
  def move(point, index, parent)
    point.parent.delete(point)
    parent.insert(index, point)
  end
  
  def appendItem(item)
    point = Point.new(@root, item, item.name)
    hashPoint(point)
  end
  
  def duplicate(point)
    new_point = Point.new(point.parent, point.item, point.text)
    @hash[new_point.id] = new_point
    new_point
  end
  
  def delete(point)
    each do |pt|
      index = pt.index(point)
      return dehashPoint(pt.delete_at(index)) if index
    end
  end

  def pointWithId(identifier)
    @hash[identifier]
  end
  
  def save(directory)
    File.open("#{directory}/#{@ncx_name}", 'w') {|f| f.write(to_xml)}
  end

  def to_xml
    navigation = self
    ERB.new(Bundle.template("toc.ncx")).result(binding)
  end
  
  private
  
  def hashPoint(point)
    raise "Navigation point ID already exists: id=#{point.id}" if @hash[id]      
    @hash[point.id] = point
    point
  end
  
  def dehashPoint(point)
    @hash[point.id] = nil
    point
  end

end
