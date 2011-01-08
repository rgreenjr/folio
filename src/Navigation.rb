class Navigation

  attr_accessor :id, :title, :creator, :docAuthor, :root

  def initialize(book=nil)
    @hash  = {}
    @id = UUID.create
    @ncx_name = "toc.ncx"
    @title = "untitled"
    @docAuthor = ""
    @root = Point.new
    @root.expanded = true

    return unless book

    doc = REXML::Document.new(book.manifest.ncx.content)
    @ncx_name = book.manifest.ncx.name
    prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''
    uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"]
    # check for 'dtb:PrimaryID' as last resort (is this standard compliant?)
    uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:PrimaryID']"] unless uid
    raise "Navigation id not found" unless uid
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
        raise "Navigation point reference not found: src=#{href}" unless item

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
  rescue Exception => exception
    Alert.runModal("Unable to open #{book.fileURL.path} because an error occurred while parsing NCX.", exception.message)
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

  def index_and_parent(point)
    each do |parent|
      index = parent.index(point)
      return index, parent if index
    end
  end

  def insert(point, index, parent)
    raise "Navigation point ID already exists: id=#{point.id}" if @hash[id]      
    @hash[point.id] = point
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
    index, parent = index_and_parent(point)
    clone = Point.new(point.item, point.text)
    parent.insert(index + 1, clone)
    @hash[clone.id] = clone
    clone
  end

  def delete(point)
    index, parent = index_and_parent(point)
    parent.delete_at(index)
    @hash[point.id] = nil
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

  def to_s
    buffer = "@navigation = {\n"
    @hash.each do |id, point|
      buffer << "  id=#{id} => href=#{point.item.href}\n"
    end
    buffer << "}"
    buffer
  end

end