class Search
  
  attr_accessor :query, :matches
  
  def initialize(query, book)
    @matches = []
    @query = query
    unless query.empty?
      book.manifest.each do |item|
        next unless item.editable?
        offset = 0
        parent = Match.new(item)
        while index = item.content.index(query, offset)
          parent << Match.new(item, parent, query, index)
          offset = index + query.size
        end
        @matches << parent unless parent.empty?
      end
    end
  end
  
  def each(&block)
    @matches.each(&block)
  end
  
  def [](index)
    @matches[index]
  end
  
  def size
    @matches.size
  end
  
  def total
    @total ||= @matches.inject(0) {|sum, m| sum += m.size}
  end
  
  def walk(index)
    stack = @matches.dup
    while stack.size > 0
      match = stack.shift
      return match if index == 0
      index -= 1
      if match.expanded
        match.each_with_index {|hit, i| stack.insert(i, hit)}
      end
    end
    nil
  end
  
end