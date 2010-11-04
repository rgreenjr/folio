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

# indices = NSIndexSet.indexSetWithIndexesInRange(NSMakeRange(2, 6))
# indices.each {|i| p i }
# p indices.to_a
