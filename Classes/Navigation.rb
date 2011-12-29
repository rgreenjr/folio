class Navigation

  # Navigation Center eXtended (NCX) Table of Contents
  
  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book=nil)
    @pointIdMap  = {}
    @id = UUID.create
    @ncx_name = "toc.ncx"
    @title = "untitled"
    @docAuthor = ""
    @root = Point.new
    @root.text = "__ROOT__"
    @root.expanded = true

    return unless book
    
    begin
      doc = REXML::Document.new(book.manifest.ncx.content)    
      @ncx_name = book.manifest.ncx.name
      prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''
      uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"]
      # check for 'dtb:PrimaryID' as last resort (is this standard compliant?)
      uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:PrimaryID']"] unless uid
      raise "The \"#{@ncx_name}\" file does not specify a 'dtb:uid'." unless uid
      @id = uid.attributes["content"]
      @title = doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text

      if doc.elements["/ncx/docAuthor/text"]
        @docAuthor = doc.elements["/ncx/docAuthor/text"].text
      end

      point_stack = [@root]
      xml_stack = [doc.elements["/#{prefix}ncx/#{prefix}navMap"]]
      while point_stack.size > 0
        parent = point_stack.shift
        element = xml_stack.shift
        element.elements.each_with_index("#{prefix}navPoint") do |e, i|

          href, fragment = e.elements["#{prefix}content"].attributes["src"].split("#")

          item = book.manifest.itemWithHref(href)
          raise "The resource \"#{href}\" is referenced in the navigation, but could not be found in the manifest." unless item

          childPoint           = Point.new
          childPoint.id        = e.attributes["id"]
        
          childPoint.playOrder = e.attributes["playOrder"]
          childPoint.text      = e.elements["#{prefix}navLabel/#{prefix}text"].text
          childPoint.item      = item
          childPoint.fragment  = fragment

          insert(childPoint, -1, parent)

          point_stack.insert(i, childPoint)
          xml_stack.insert(i, e)
        end
      end
    rescue REXML::ParseException => exception
      raise StandardError, "An error occurred while parsing #{book.manifest.ncx.href}: #{exception.explain}"
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
  
  def select(&block)
    points = []
    each(true) do |point| 
      points << point if yield(point)
    end
    points
  end

  def [](index)
    each_with_index do |point, idx|
      return point if index - idx == -1
    end
  end

  def indexAndParent(point)
    if point
      each(true) do |parent|
        index = parent.index(point)
        return index, parent if index
      end
    end
    nil
  end

  def insert(point, index, parent)
    raise "A point with ID \"#{point.id}\" already exists in the navigation." if hasPointWithId?(id)
    @pointIdMap[point.id] = point
    parent.insert(index, point)
  end

  def move(point, index, parent)
    delete(point)
    insert(point, index, parent)
  end

  def appendItem(item)
    point = Point.new(item, item.name)
    insert(point, -1, @root)
  end

  def duplicate(point)
    index, parent = indexAndParent(point)
    clone = Point.new(point.item, point.text)
    parent.insert(index + 1, clone)
    @pointIdMap[clone.id] = clone
    clone
  end

  def delete(point)
    index, parent = indexAndParent(point)
    parent.delete_at(index)
    @pointIdMap[point.id] = nil
  end

  def pointWithId(identifier)
    @pointIdMap[identifier]
  end
  
  def hasPointWithId?(identifier)
    pointWithId(identifier) != nil
  end

  def changePointId(point, newID)
    return nil if pointWithId(newID)
    @pointIdMap[point.id] = nil
    oldID = point.id
    point.id = newID
    @pointIdMap[point.id] = point
    oldID
  end
  
  def save(directory)
    filepath = File.join(directory, @ncx_name)
    File.open(filepath, 'w') {|f| f.write(to_xml)}
  end

  def to_xml
    navigation = self
    ERB.new(Bundle.template("toc.ncx")).result(binding)
  end

  def to_s
    buffer = "@navigation = {\n"
    @pointIdMap.each do |id, point|
      buffer << "  id=#{id} => href=#{point.item.href}\n"
    end
    buffer << "}"
    buffer
  end

end