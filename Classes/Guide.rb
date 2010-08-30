class Guide
  
  def initialize
    @items = []
  end

  def size
    @items.size
  end

  def [](index)
    @items[index]
  end

  def each
    @items.each {|i| yield i}
  end

  def <<(item)
    @items << item
  end
  
end