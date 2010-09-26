class Match
  
  attr_accessor :item, :message, :range, :hits, :expanded
  
  def initialize(item, query=nil, index=nil)
    @hits = []
    @item = item
    if index
      start = [index - 15, 0].max
      stop = query.size + 30
      @range = NSRange.new(index, query.size)
      @message = item.content[start, stop].gsub(/[\r\n\t]/, ' ')
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
  
  def <<(match)
    @hits << match
  end
  
  def empty?
    size == 0
  end

end