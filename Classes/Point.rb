class Point

  attr_accessor :id, :playOrder, :text
  attr_accessor :item, :fragment, :expanded

  def initialize
    @children = []
  end
  
  def src
    @fragment ? "#{@item.href}##{@fragment}" : @item.href
  end
  
  def uri
    u = @item.uri.dup
    u.fragment = @fragment
    u
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
    buffer << "#{padding}  <content src=\"#{src}\"/>\n"
    @children.each do |p|
      buffer << p.to_xml(indent + 1)
    end
    buffer << "#{padding}</navPoint>\n"
  end
  
  def editable?
    @item.editable?
  end
  
  def content
    @item.content
  end

  def content=(string)
    @item.content = string
  end

end

