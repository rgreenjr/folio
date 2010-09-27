class Match
  
  attr_accessor :item, :message, :range, :expanded
  
  def initialize(item, query=nil, index=nil)
    @hits = []
    @item = item
    if index
      start = [index - 15, 0].max
      stop = query.size + 30
      @range = NSRange.new(index, query.size)
      @message = item.content[start, stop].gsub(/\s/, ' ')
    else
      @message = item.name
    end
  end

  def size
    @hits.size
  end
  
  def [](index)
    @hits[index]
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
  
end