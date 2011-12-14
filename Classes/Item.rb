class Item

  PBOARD_TYPE = "ItemPboardType"

  # mandatory unique identifier within the container
  attr_accessor :id
  
  # mandatory MIME media-type
  attr_accessor :mediaType
  
  attr_accessor :content, :name, :parent

  def initialize(parent, name, id=nil, mediaType=nil, expanded=false)
    @parent = parent
    @name = name
    @id = id || UUID.create
    @mediaType = mediaType || Media.guessType(File.extname(name))
    @expanded = expanded
    @children = []
    @issueHash = {}    
    FileUtils.mkdir(path) if directory? && !File.exists?(path)
    # scanContentForIDAttributes
  end
  
  def item
    self
  end
  
  def path
    @parent ? File.join(@parent.path, @name) : @name
  end
  
  def href
    return '' unless @parent
    @parent.href == '' ? @name : "#{@parent.href}/#{@name}"
  end
  
  def url
    NSURL.fileURLWithPath(path)
  end

  def content
    @content ||= File.read(path)
  end
  
  def content=(string)
    @lastSavedContent = @content.dup unless @lastSavedContent || @content.nil?
    @content = string.dup
    File.open(path, 'wb') {|f| f.puts @content}
  end

  def name=(name)
    name = name.sanitize
    unless name.empty?
      old = path
      @name = name
      File.rename(old, path)
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

  def editable?
    Media.editable?(@mediaType)
  end

  def renderable?
    Media.renderable?(@mediaType)
  end
  
  def imageable?
    Media.imageable?(@mediaType)
  end
  
  def flowable?
    Media.flowable?(@mediaType)
  end
  
  def formatable?
    Media.formatable?(@mediaType)
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
  
  def ancestor?(item)
    return true if item == self
    each {|child| return true if child.ancestor?(item)}
    false
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
    File.open(path, 'wb') {|f| f.puts content}
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
    base = childname.stringByDeletingPathExtension
    while true
      if childWithName(candidate)
        counter += 1
        candidate = "#{base} #{counter}.#{extension}" 
      else
        break
      end
    end
    candidate
  end
  
  # used for sorting
  def <=>(other)
    @name <=> other.name
  end

  def imageRep
    return nil unless imageable?
    @image ||= NSImage.alloc.initWithContentsOfFile(path)
  end

  def issues
    @issueHash.values.sort
  end
  
  def hasIssues?
    !@issueHash.empty?
  end
  
  def issueHash
    @issueHash
  end

  def clearIssues
    @issueHash.clear
  end
  
  def addIssue(issue)
    @issueHash[issue.lineNumber] = issue
  end
  
  def scanContentForIDAttributes
    @async = AsyncCommand.new do
      id_links = []
      if flowable?
        REXML::XPath.each(REXML::Document.new(content), "//*[@id]") do |element|
          # puts "item #{name}: #{element}"
          id_links << element.to_s
        end
      end
      id_links
    end
  end

end