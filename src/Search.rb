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
          parent << Match.new(item, query, index)
          offset = index + query.size
        end
        @matches << parent unless parent.empty?
      end
    end
  end
  
  def [](index)
    stack = @matches.dup
    while stack.size > 0
      match = stack.shift
      return match if index == 0
      index -= 1
      if match.expanded
        match.hits.each_with_index {|child, i| stack.insert(i, child)}
      end
    end
  end
  
  def size
    @matches.size
  end
  
end