class Item

  PBOARD_TYPE = "ItemPboardType"

  attr_accessor :id             # mandatory unique identifier within the container
  attr_accessor :mediaType      # mandatory MIME media-type
  attr_accessor :referenceType
  attr_accessor :referenceTitle
  attr_accessor :content
  attr_accessor :name
  attr_accessor :parent
  attr_reader   :parsingError

  def initialize(parent, name, id=nil, mediaType=nil, expanded=false)
    @parent = parent
    @name = name
    @id = id || UUID.create
    @mediaType = mediaType || Media.guessType(File.extname(name))
    @expanded = expanded
    @children = []
    @issues = []    
    FileUtils.mkdir(absolutePath) if directory? && !File.exists?(absolutePath)
  end

  # allows points, itemRefs, and items to be treated interchangeably 
  # when accessing item objects using object.item
  def item
    self
  end

  def absolutePath
    @parent ? File.join(@parent.absolutePath, @name) : @name
  end

  def hasParent?
    @parent != nil
  end

  def href
    return '' unless hasParent?
    @parent.hasParent? ? "#{@parent.href}/#{@name}" : @name
  end

  def url
    NSURL.fileURLWithPath(absolutePath)
  end

  def content
    @content ||= File.read(absolutePath)
  end

  def content=(string)
    @lastSavedContent = @content.dup unless @lastSavedContent || @content.nil?
    @content = string.dup
    File.open(absolutePath, 'wb') {|f| f.puts @content}
    @xmlDocument = nil
    @fragments = nil
    @parsingError = nil
  end

  def name=(name)
    name = name.sanitize
    unless name.empty?
      old = absolutePath
      @name = name
      File.rename(old, absolutePath)
    end
    @name
  end

  def mediaType=(value)
    unless value.empty?
      @mediaType = value
    end
    @mediaType
  end

  def id=(value)
    unless value.empty?
      @id = value
    end
    @id
  end

  def links
    @async.value
  end

  def renderable?
    Media.renderable?(@mediaType)
  end

  def imageable?
    Media.imageable?(@mediaType)
  end

  def textual?
    Media.textual?(@mediaType)
  end

  def parseable?
    Media.parseable?(@mediaType)
  end

  def spineable?
    Media.spineable?(@mediaType)
  end

  def ncx?
    Media.ncx?(@mediaType)
  end

  def directory?
    Media.directory?(@mediaType)
  end

  def expanded?
    @expanded
  end

  def expanded=(bool)
    @expanded = bool
  end

  def leaf?
    @children.empty?
  end

  def size
    @children.size
  end

  def [](index)
    @children[index]
  end

  def each(&block)
    @children.each(&block)
  end

  def each_with_index(&block)
    @children.each_with_index(&block)
  end

  def <<(item)
    item.parent = self
    @children << item
  end

  def childWithName(name)
    @children.find {|item| item.name == name}
  end

  def hasChildWithName?(name)
    childWithName(name) != nil
  end

  def index(item)
    each_with_index { |i, index| return index if item == i }
    nil
  end

  def insert(index, item)
    index = -1 if index > size
    item.parent = self
    @children.insert(index, item)
  end

  def delete(item)
    if index(item)
      item.parent = nil
      @children.delete(item)
    end
  end

  def delete_at(index)
    @children[index].parent = nil
    @children.delete_at(index)
  end

  def save
    File.open(absolutePath, 'wb') {|f| f.puts content}
    @lastSavedContent = nil
  end

  def saveToDirectory(directory)
    file = File.join(directory, href)
    if directory?
      FileUtils.mkdir_p(file)
    else
      File.open(file, 'wb') {|f| f.puts content}
    end
  end

  def revert
    if @lastSavedContent
      @content = @lastSavedContent.dup
      @lastSavedContent = nil
    end
  end

  def edited?
    @lastSavedContent != nil
  end

  def sort
    @children.sort!
    @children.each { |item| item.sort }
  end

  def generateUniqueChildName(childname, counter=0)
    candidate = childname
    extension = childname.pathExtension
    extension = '.' + extension unless extension.empty?
    base = childname.stringByDeletingPathExtension
    while hasChildWithName?(candidate)
      counter += 1
      candidate = "#{base} #{counter}#{extension}" 
    end
    candidate
  end

  def <=>(other)
    @name <=> other.name
  end

  def ==(other)
    other.class == Item && other.id == @id
  end

  def imageRep
    return nil unless imageable?
    @image ||= NSImage.alloc.initWithContentsOfFile(absolutePath)
  end

  def fileSize
    if textual?
      content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    else
      NSFileManager.defaultManager.attributesOfItemAtPath(absolutePath, error:nil).fileSize
    end
  end

  def issues
    @issues.sort
  end

  def hasIssues?
    issueCount > 0
  end

  def issueCount
    @issues.size
  end

  def clearIssues
    @issues = []
  end

  def addIssue(issue)
    @issues << issue if issue
  end

  def issueForLine(line)
    @issues.sort.find { |issue| issue.lineNumber == line }
  end

  # returns an arrays of strings or nil if parsing fails
  def fragments
    return [] unless parseable?
    unless @fragments
      nodes = fragmentNodes
      if nodes
        @fragments = []
        nodes.each do |node|
          node.attributes.each do |attribute|
            @fragments << attribute.stringValue if attribute.name == 'id'
          end
        end
      end
    end
    @fragments
  end

  def closestFragment(string)
    fragments.find {|frag| frag.match(/^#{string}/i)} unless fragments.nil?
  end

  def containsFragment?(fragment)
    fragment && fragments && fragments.include?(fragment)
  end

  def fragmentsCached?
    @fragments != nil
  end

  def valid?
    clearIssues
    addIssue Issue.new("ID cannot be blank.") if @id.blank?
    addIssue Issue.new("Name cannot be blank.") if @name.blank?
    addIssue Issue.new("Media Type cannot be blank.") if @mediaType.blank?
    addIssue Issue.new("Media Type \"#{@mediaType}\" is invalid.") unless Media.validMediaType?(@mediaType)
    if parseable?
      XMLLint.validate(content, @mediaType, @issues)
      validateFragments
    elsif imageable?
      BitmapChecker.validate(item, @issues)
    end
    @issues.empty?
  end

  # checks for fragment ids being used more than once
  def validateFragments
    duplicates = []
    if fragments
      hash = Hash.new(0)
      fragments.each do |id|
        hash[id] += 1
      end
      hash.each do |id, count|
        duplicates << id if count > 1
      end
    end
    duplicates.each do |duplicate|
      addIssue Issue.new("The fragment \"#{duplicate}\" already exists.")
    end
  end

  def parseXMLContent
    unless @xmlDocument
      error = Pointer.new(:id)
      @xmlDocument = NSXMLDocument.alloc.initWithXMLString(content, options:0, error:error)
      addXMLError(error[0]) if error[0]
    end
    @xmlDocument
  end

  def imageNodes
    return [] unless parseable?
    nodesForXPath("//img[@src]")
  end
  
  def anchorNodes
    return [] unless parseable?
    nodesForXPath("//a[@href]")
  end
  
  def fragmentNodes
    return [] unless parseable?
    nodesForXPath("//*[@id]")
  end
  
  def nodesForXPath(xpath)
    nodes = []
    doc = parseXMLContent
    if doc
      error = Pointer.new(:id)      
      nodes = doc.nodesForXPath(xpath, error:error)
      addXMLError(error[0]) if error[0]
    end
    nodes
  end

  def addXMLError(error)
    @parsingError = error.localizedDescription        
    addIssue(Issue.new($2, $1)) if @parsingError =~ /Line (\d+): (.*)/
  end
  
  def self.findFragments(document)
    error = Pointer.new(:id)
    array = document.nodesForXPath("//*[@id]", error:error)
    raise StandardError, error[0].localizedDescription if error[0]
    fragments = []
    array.each do |element|
    end
    fragments
  end

end
