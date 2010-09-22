class Point

  attr_accessor :id, :playOrder, :text, :item, :fragment

  def initialize(expanded=false)
    @id, @text, @expanded, @children = UUID.create, "", expanded, []
  end

  def uri
    URI.join('file:/', @item.path.gsub(/ /, '%20'), fragment)
  end

  def src
    "#{@item.href}#{fragment}"
  end

  def fragment
    @fragment ? "##{@fragment}" : ""
  end

  def text=(string)
    if string
      string = string.strip
      @text = string if string.size > 0
    end
  end

  def depth
    1 + @children.inject(0) {|max, point| [point.depth, max].max}
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

  def <<(point)
    @children << point
  end

  def index(point)
    each_with_index { |pt, index| return index if point.id == pt.id }
    nil
  end

  def insert(index, point)
    @children.insert(index, point)
  end

  def delete_at(index)
    @children.delete_at(index)
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