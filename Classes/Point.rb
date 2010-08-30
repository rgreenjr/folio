class Point

  attr_accessor :id, :playOrder, :text, :src, :uri, :expanded

  def initialize(base=nil, element=nil, prefix=nil)
    @children = []
    @expanded = element.nil?
    if element
      @id        = element.attributes["id"]
      @playOrder = element.attributes["playOrder"]
      @text      = element.elements["#{prefix}navLabel/#{prefix}text"].text
      @src       = element.elements["#{prefix}content"].attributes["src"]
      @base      = base
      @uri       = "file://#{base}/#{src}"
      element.elements.each("#{prefix}navPoint") do |e|
        @children << Point.new(base, e, prefix)
      end
    end
  end
  
  def text=(string)
    string = string.strip
    @text = string if string.size > 0
  end
  
  def depth
    1 + @children.inject(0) {|max, point| [point.depth, max].max}
  end

  def size
    @children.size
  end

  def [](index)
    @children[index]
  end

  def each
    @children.each {|point| yield point}
  end

  def each_with_index
    @children.each_with_index {|point, index| yield point, index}
  end

  def <<(point)
    @children << point
  end

  def to_xml(indent=1)
    buffer = ""
    padding = "  " * indent
    buffer << "#{padding}<navPoint id=\"#{@id}\" playOrder=\"#{@playOrder}\">\n"
    buffer << "#{padding}  <navLabel>\n"
    buffer << "#{padding}    <text>#{@text}</text>\n"
    buffer << "#{padding}  </navLabel>\n"
    buffer << "#{padding}  <content src=\"#{@src}\"/>\n"
    @children.each do |p|
      buffer << p.to_xml(indent + 1)
    end
    buffer << "#{padding}</navPoint>\n"
  end

end

