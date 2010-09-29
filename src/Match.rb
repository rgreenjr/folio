class Match
  
  attr_accessor :parent, :item, :message, :range, :expanded, :changed
  
  def initialize(item, parent=nil, query=nil, index=nil)
    @hits = []
    @item = item
    if parent
      start = [index - 15, 0].max
      stop = query.size + 30
      @parent = parent
      @range = NSRange.new(index, query.size)
      @message = @item.content[start, stop].gsub(/\s/, ' ')
    else
      @message = @item.name
    end
  end

  def size
    @hits.size
  end
  
  def [](index)
    @hits[index]
  end
  
  def each(&block)
    @hits.each(&block)
  end
  
  def each_with_index(&block)
    @hits.each_with_index(&block)
  end
  
  def <<(match)
    @hits << match
  end
  
  def empty?
    @hits.empty?
  end
  
  def leaf?
    size == 0
  end
  
  def slide(amount)
    unless changed
      print "sliding #{amount}: #{@item.content[@range.location..@range.length]} => "
      @range.location += amount
      puts "#{@item.content[@range.location..@range.length]}"
    end
  end
  
end