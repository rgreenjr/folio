require 'open-uri'

class Item

  attr_accessor :id, :href, :mediaType, :content, :name, :uri

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
    save
  end
  
  def name=(string)
    string = string.strip.gsub(%r{[/"*:<>\?\\]}, '_')
    @name = string if string.size > 0
  end
  
  def links
    puts @href
    REXML::XPath.each(REXML::Document.new(content), "//*[@id]") do |element|
      puts element
    end
    puts "-------------------"
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
    return unless tidyable?
    self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{@href}'`
  end

  def directory?
    @mediaType == 'directory'
  end

  def leaf?
    @children.empty?
  end

  def expanded?
    @expanded
  end
  
  def expanded=(flag)
    @expanded = flag
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
    @children << item
  end

  def find(name)
    @children.find {|item| item.name == name}
  end
  
  def save
    File.open(@uri.path, 'wb') {|file| file.puts @content}
  end
  
  def to_xml
    "    <item id=\"#{@id}\" href=\"#{@href}\" media-type=\"#{@mediaType}\"/>"
  end

  private
  
  def uuid
    (1..4).map { (0..8).map{ rand(16).to_s(16) }.join }.join('-')
  end

end