class Item

  attr_accessor :id, :mediaType, :content, :name, :parent

  def initialize(parent, name, id=nil, mediaType=nil, expanded=false)
    @parent = parent
    @name = name
    @id = id || UUID.create
    @mediaType = mediaType || Media.guessType(File.extname(name))
    @expanded = expanded
    @children = []
    @markerHash = {}    
    FileUtils.mkdir(path) if directory? && !File.exists?(path)
    # scanContentForIDAttributes
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
  
  def links
    @async.value
  end

  def editable?
    %w{application/xml application/xhtml+xml text/css application/x-dtbncx+xml}.include?(@mediaType)
  end

  def renderable?
    %w{application/xml application/xhtml+xml image/jpeg image/png image/gif image/svg+xml text/css}.include?(@mediaType)
  end
  
  def imageable?
    %w{image/jpeg image/png image/gif image/svg+xml}.include?(@mediaType)
  end
  
  def flowable?
    %w{application/xml application/xhtml+xml}.include?(@mediaType)
  end
  
  def formatable?
    %w{application/xml application/xhtml+xml}.include?(@mediaType)
  end

  def ncx?
    @mediaType == "application/x-dtbncx+xml"
  end

  def directory?
    @mediaType == 'directory'
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

  # used for sorting
  def <=>(other)
    @name <=> other.name
  end

  def imageRep
    return nil unless imageable?
    @image ||= NSImage.alloc.initWithContentsOfFile(path)
  end

  def guessMediaType
  end
  
  def markers
    @markerHash.values
  end
  
  def markerHash
    @markerHash
  end

  def clearMarkers
    @markerHash.clear
  end
  
  def addMarker(marker)
    @markerHash[marker.lineNumber] = marker
  end
  
  def removeMarker(lineNumber)
    @markerHash[marker.lineNumber] = nil
  end

  def scanContentForIDAttributes
    @async = Async.new do
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