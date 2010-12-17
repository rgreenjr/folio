class NSIndexSet

  def each
    i = firstIndex
    while i != NSNotFound
      yield i
      i = indexGreaterThanIndex(i)
    end
  end
  
  def empty?
    count == 0
  end
  
  def size
    count
  end

  include Enumerable
end
