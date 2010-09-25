class Match
  
  attr_accessor :item, :message, :range
  
  def initialize(item, query, index)
    start = [index - 10, 0].max
    stop = query.size + 10
    @item = item
    @message = "#{item.name} #{item.content[start, stop]}"
    @range = NSRange.new(index, query.size)
  end

end