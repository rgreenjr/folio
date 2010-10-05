class Item

  attr_accessor :id, :mediaType, :content, :name, :parent

  def initialize(parent, name, id, mediaType, expanded=false)
    @parent, @name, @id, @mediaType, @expanded, @children = parent, name, id, mediaType, expanded, []
  end
  
  def path
    @parent ? File.join(@parent.path, @name) : @name
  end
  
  def href
    return '' unless @parent
    @parent.href == '' ? @name : "#{@parent.href}/#{@name}"
  end
  
  def uri
    URI.join('file:/', path.gsub(/ /, '%20'))
  end

  def content
    @content ||= File.read(path)
  end
  
  def content=(string)
    @lastSavedContent = @content.dup unless @lastSavedContent
    @content = string
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
    REXML::XPath.each(REXML::Document.new(content), "//*[@id]") do |element|
      puts element
    end
  rescue
    nil
  end

  def editable?
    %w{application/xml application/xhtml+xml text/css application/x-dtbncx+xml}.include?(@mediaType)
  end

  def tidyable?
    %w{application/xml application/xhtml+xml}.include?(@mediaType)
  end

  def renderable?
    %w{application/xml application/xhtml+xml image/jpeg image/png image/gif image/svg+xml text/css}.include?(@mediaType)
  end

  def ncx?
    @mediaType == "application/x-dtbncx+xml"
  end

  def tidy
    if tidyable?
      self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{href}'`
    end
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

  def find(name)
    @children.find {|item| item.name == name}
  end
  
  def contains?(item)
    return true if item == self
    each {|child| return true if child.contains?(item)}
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
  
  def save
    puts "save"
    File.open(path, 'wb') {|f| f.puts @content}
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
      @content = @lastSavedContent
      @lastSavedContent = nil
    end
  end
  
  def edited?
    @lastSavedContent != nil
  end

end