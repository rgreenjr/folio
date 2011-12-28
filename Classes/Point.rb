class Point

  PBOARD_TYPE = "PointPboardType"

  attr_accessor :id, :playOrder, :text, :item, :fragment

  def initialize(item=nil, text=nil, id=nil, fragment='')
    @item = item
    if text
      @text = text
    else
      @text = @item ? @item.name : ""
    end
    @id = id || UUID.create
    @fragment = fragment
    @children = []
  end

  def url
    encoded = @item.path.gsub(' ', '%20')
    url = NSURL.URLWithString(encoded + fragmentWithHash)
  end
  
  def src
    @item.href + fragmentWithHash
  end
  
  def text=(value)
    value = value.strip if value
    @text = value.empty? ? @text : value
  end
  
  def id=(value)
    @id = value.empty? ? @id : value
  end
  
  def item=(value)
    @item = value ? value : @item
  end
  
  def fragment=(value)
    @fragment = value ? value : @fragment
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

  def children
    @children
  end

  def each(&block)
    @children.each(&block)
  end

  def each_with_index(&block)
    @children.each_with_index(&block)
  end
  
  def ancestor?(point)
    return true if point == self
    @children.any? { |child| child.ancestor?(point) }
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
  
  def ==(other)
    other.class == Point && @id == other.id
  end

  def to_s
    "@id = #{@id}, @text = #{@text}, @item = #{@item.name}, @expanded = #{@expanded}"
  end

  private
  
  def fragmentWithHash
    @fragment.empty? ? '' : "##{fragment}"
  end

end