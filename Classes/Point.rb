class Point

  attr_accessor :id, :playOrder, :text, :src, :uri, :expanded

  def initialize(base=nil, element=nil, prefix=nil)
    @points = []
    @expanded = element.nil?
    if element
      @id        = element.attributes["id"]
      @playOrder = element.attributes["playOrder"]
      @text      = element.elements["#{prefix}navLabel/#{prefix}text"].text
      @src       = element.elements["#{prefix}content"].attributes["src"]
      @base      = base
      @uri       = "file://#{base}/#{src}"
      element.elements.each("#{prefix}navPoint") do |e|
        @points << Point.new(base, e, prefix)
      end
    end
  end

  def size
    @points.size
  end

  def [](index)
    @points[index]
  end

  def each
    @points.each {|p| yield p}
  end

  def <<(point)
    @points << point
  end

  def traverse(index)
    return [self, index] if index == -1
    return [nil, index] if size == 0 || !expanded
    match = nil
    each do |p|
      match, index = p.traverse(index - 1)
      break if match
    end
    return [match, index]
  end

  def to_xml(depth=1)
    buffer = ""
    padding = "  " * depth
    buffer << "#{padding}<navPoint id=\"#{@id}\" playOrder=\"#{@playOrder}\">\n"
    buffer << "#{padding}  <navLabel>\n"
    buffer << "#{padding}    <text>#{@text}</text>\n"
    buffer << "#{padding}  </navLabel>\n"
    buffer << "#{padding}  <content src=\"#{@src}\"/>\n"
    @points.each do |p|
      buffer << p.to_xml(depth + 1)
    end
    buffer << "#{padding}</navPoint>\n"
  end

end

