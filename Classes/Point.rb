class Point

  PBOARD_TYPE = "PointPboardType"

  attr_accessor :id
  attr_accessor :playOrder
  attr_accessor :text
  attr_accessor :item
  attr_accessor :fragment
  attr_reader   :issues
  attr_accessor :root
  
  def self.root
    root = Point.new
    root.text = "__ROOT__"
    root.root = true
    root.expanded = true
    root
  end

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
    @issues = []
  end

  def url
    encoded = @item.absolutePath.gsub(' ', '%20')
    url = NSURL.URLWithString(encoded + fragmentWithHash)
  end
  
  def href
    @item.href
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
    @fragment = value ? value : ''
  end
  
  def hasFragment?
    !@fragment.blank?
  end
  
  def root?
    @root
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
    if point
      each_with_index { |pt, index| return index if point.id == pt.id }
    end
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
  
  def valid?
    clearIssues
    if hasFragment? && item && !item.containsFragment?(fragment)
      addIssue Issue.new("Item \"#{item.name}\" doesn't contain the fragment \"#{fragment}\".", nil, "Please specify an existing fragment identifier.")
    end
    addIssue(Issue.new("Point text values cannot be blank.", nil, "Please specify a value.")) if text.blank?
    addIssue(Issue.new("Point ID values cannot be blank.", nil, "Please specify a value.")) if id.blank?    
    addIssue(Issue.new("Point item reference cannot be blank.", nil, "Please specify an item.")) if item.nil? && !root?
    !hasIssues?
  end
  
  def hasIssues?
    issueCount > 0
  end
  
  def issueCount
    @issues.size
  end
  
  def clearIssues
    @issues = []
  end
  
  def addIssue(issue)
    @issues << issue if issue
  end
  
  private
  
  def fragmentWithHash
    @fragment.empty? ? '' : "##{fragment}"
  end

end