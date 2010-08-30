class Manifest

  attr_accessor :items, :root

  def initialize(book)
    @hash  = {}
    @root = Item.new("file://#{book.container.root}", book.container.base, 'ROOT', 'directory', true)
    book.container.opfDoc.elements.each("/package/manifest/item") do |e|
      parts = e.attributes["href"].split('/')
      parent = @root
      parts.each_with_index do |part, index|
        break if index == (parts.size - 1)
        directory = parent.find(part)
        if directory == nil
          directory = Item.new("#{parent.uri}/#{part}", part, part, 'directory')
          parent << directory
        end
        parent = directory
      end
      item = Item.new("#{parent.uri}/#{parts.last}", e.attributes["href"], e.attributes["id"], e.attributes["media-type"])
      parent << item
      raise "Manifest item id is not unique: #{item.id}" if @hash[item.id]      
      @hash[item.id] = item
    end
  end

  def [](index)
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      return item if index == -1
      if item.expanded
        inner = []
        item.each {|child| inner << child}
        stack = inner + stack
      end
      index -= 1
    end
  end

  def each
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      item.each {|child| stack << child}
      yield item unless item.directory?
    end
  end

  def itemWithId(identifier)
    @hash[identifier]
  end

  def save(directory)
    src  = File.join(@root.uri.path, '.')
    dest = File.join(directory, @root.href)
    FileUtils.cp_r(src, dest)
  end

end