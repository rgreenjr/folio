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

  def each(&block)
    @items.each(&block)
  end

  def <<(item)
    @items << item
  end
  
end