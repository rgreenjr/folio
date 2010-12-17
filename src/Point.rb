class Point

  attr_accessor :parent, :id, :playOrder, :text, :item, :fragment

  def initialize(parent=nil, item=nil, text=nil)
    @parent = parent
    @item = item
    if text
      @text = text
    else
      @text = item ? item.name : ""
    end
    @id = UUID.create
    @expanded = parent ? false : true
    @children = []
    @parent << self if @parent
  end

  def uri
    URI.join('file:/', @item.path.gsub(/ /, '%20'), fragment)
  end

  def url
    NSURL.URLWithString(uri.to_s)
  end

  def src
    "#{@item.href}#{fragment}"
  end

  def fragment
    @fragment.empty? ? "" : "##{@fragment}"
  end

  def text=(text)
    if text
      text = text.strip
      @text = text unless text.empty?
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
  
  def ancestor?(point)
    return true if point == self
    each {|child| return true if child.ancestor?(point)}
    false
  end
  
  def <<(point)
    @children << point
  end

  def index(point)
    each_with_index { |pt, index| return index if point.id == pt.id }
    nil
  end

  def insert(index, point)
    index = -1 if index > size
    point.parent = self # does this need to be done elsewhere in Point ???!!!!???
    @children.insert(index, point)
  end
  
  def delete(point)
    delete_at(index(point))
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

  def name
    @item.name
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