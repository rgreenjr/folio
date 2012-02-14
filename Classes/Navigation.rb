# Navigation Center eXtended (NCX) Table of Contents
class Navigation

  attr_accessor :id
  attr_accessor :title
  attr_accessor :docAuthor
  attr_accessor :creator
  attr_accessor :root

  def self.load(package)
    navigation = Navigation.new(package)
    
    # parse NCX file
    doc = parseNCX(package.manifest.ncx)

    # determine namespace prefix
    prefix = (doc.root.prefix != '') ? "#{doc.root.prefix}:" : ''
    
    navigation.id = extractID(doc, prefix)        
    navigation.title = extractDocTitle(doc, prefix)
    navigation.docAuthor = extractDocAuthor(doc)

    pointStack = [navigation.root]
    xmlStack = [doc.elements["/#{prefix}ncx/#{prefix}navMap"]]
    while pointStack.size > 0
      parent = pointStack.shift
      element = xmlStack.shift
      element.elements.each_with_index("#{prefix}navPoint") do |element, index|

        href, fragment = element.elements["#{prefix}content"].attributes["src"].split("#")

        item = package.manifest.itemWithHref(href)
        raise "The item \"#{href}\" is referenced in the navigation, but could not be found in the manifest." unless item

        childPoint = Point.new
        childPoint.id = element.attributes["id"]

        childPoint.playOrder = element.attributes["playOrder"]
        childPoint.text = element.elements["#{prefix}navLabel/#{prefix}text"].text
        childPoint.item = item
        childPoint.fragment = fragment

        navigation.insert(childPoint, -1, parent)

        pointStack.insert(index, childPoint)
        xmlStack.insert(index, element)
      end
    end
    navigation
  end

  def initialize(package)
    @package = package
    @root = Point.root
    @id = UUID.create
    @title = "untitled"
    @docAuthor = ""
    @pointIdMap = {}
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

  def save(directoryPath)
    File.open(File.join(directoryPath, @package.manifest.ncx.name), 'w') { |f| f.write ncxXML }
  end

  def ncxXML
    ERB.new(Bundle.template("toc.ncx")).result(binding)
  end

  def validate(issues)
    each(true) do |point|
      issues += point.issues unless point.valid?
    end
  end

  def size
    count = 0
    each(true) { count += 1 }
    count
  end
  
  private
  
  def self.parseNCX(ncx)
    begin
      doc = REXML::Document.new(ncx.content)    
    rescue REXML::ParseException => exception
      raise "Unable to parse NCX file \"#{ncx.href}\": #{exception.explain}"
    end
  end

  def self.extractID(doc, prefix)
    uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:uid']"]    
    if uid.blank?
      # check for 'dtb:PrimaryID' as last resort (not sure if this standards compliant)
      uid = doc.elements["/#{prefix}ncx/#{prefix}head/#{prefix}meta[@name='dtb:PrimaryID']"]
      raise "The NCX file \"#{package.manifest.ncx.name}\" doesn't specify a 'dtb:uid'." unless uid
    end
    uid.attributes["content"]
  end

  def self.extractDocTitle(doc, prefix)
    doc.elements["/#{prefix}ncx/#{prefix}docTitle/#{prefix}text"].text
  end
  
  def self.extractDocAuthor(doc)
    doc.elements["/ncx/docAuthor/text"] ? doc.elements["/ncx/docAuthor/text"].text : ""
  end

end