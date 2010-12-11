class NSIndexSet

  def each
    i = firstIndex
    while i != NSNotFound
      yield i
      i = indexGreaterThanIndex(i)
    end
  end

  include Enumerable
end
