require 'open-uri'

class Item

  attr_accessor :base, :fullpath, :content, :extname, :name, :uri
  attr_accessor :id, :href, :mediaType, :referenceTitle, :referenceType

  attr_accessor :expanded

  def initialize(uri, id, mediaType)
    @id = id
    @uri = uri
    @href = URI.parse(@uri).path
    @mediaType = mediaType
    @name = @href.split('/').last
    @children = []
    @expanded = true if @mediaType == 'ROOT'
    p self
  end

  def content
    puts "@href = #{@href}"
    @content ||= File.read(@href)
  end

  def content=(content)
    @content = content
    File.open(@href, 'wb') {|f| f.puts @content}
  end

  def editable?
    %w{application/xml application/xhtml+xml text/css application/x-dtbncx+xml}.include?(@mediaType)
  end

  def tidyable?
    %w{application/xml application/xhtml+xml}.include?(@mediaType)
  end

  def renderable?
    %w{application/xml application/xhtml+xml text/css image/jpeg image/png image/gif image/svg+xml}.include?(@mediaType)
  end

  def manifestable?
    # application/x-dtbncx+xml
    %w{.opf .ncx .plist}.include?(File.extname(@href)) == false
  end

  def tidy
    return unless tidyable?
    self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{@fullpath}'`
  end

  def size
    @children.size
  end

  def [](index)
    @children[index]
  end

  def each
    @children.each {|i| yield i}
  end

  def <<(item)
    @children << item
  end

  def traverse(depth)
    return [self, depth] if depth == -1
    return [nil, depth] if size == 0 || !expanded
    match = nil
    each do |p|
      match, depth = p.traverse(depth - 1)
      break if match
    end
    return [match, depth]
  end

  def find(name)
    each {|item| return item if item.name == name}
    nil
  end

end