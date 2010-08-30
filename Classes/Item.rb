require 'open-uri'

class Item

  attr_accessor :id, :href, :mediaType, :content, :name, :uri, :expanded

  def initialize(uri, href, id, mediaType, expanded=false)
    @id = id
    @uri = URI.parse(uri)
    @href = href
    @mediaType = mediaType
    @name = @href.split('/').last
    @children = []
    @expanded = expanded
  end
  
  def content
    @content ||= File.read(@uri.path)
  end

  def content=(content)
    @content = content
    File.open(@href, 'wb') {|f| f.puts @content}
  end
  
  def name=(string)
    string = string.strip.gsub(%r{[/"*:<>\?\\]}, '_')
    @name = string if string.size > 0
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

  def manifestable?
    # application/x-dtbncx+xml
    %w{.opf .ncx .plist}.include?(File.extname(@href)) == false
  end

  def tidy
    return unless tidyable?
    self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{@href}'`
  end

  def directory?
    @mediaType == 'directory'
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

  def each
    @children.each {|item| yield item}
  end

  def each_with_index
    @children.each_with_index {|item, index| yield item, index}
  end

  def <<(item)
    @children << item
  end

  def find(name)
    each {|item| return item if item.name == name}
    nil
  end
  
  def to_xml
    "    <item id=\"#{@id}\" href=\"#{@href}\" media-type=\"#{@mediaType}\"/>"
  end

end