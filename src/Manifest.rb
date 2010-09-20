class Manifest

  attr_accessor :items, :root, :ncx

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
      if item.ncx?
        ncxID = book.container.opfDoc.elements["/package/spine"].attributes["toc"]
        @ncx = item if item.id == ncxID
      else
        parent << item
        raise "Manifest item id is not unique: #{item.id}" if @hash[item.id]      
        @hash[item.id] = item
      end
    end
  end

  def [](index)
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      return item if index == -1
      if item.expanded?
        item.each_with_index {|child, i| stack.insert(i, child)}
      end
      index -= 1
    end
  end

  def each
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      item.each {|child| stack << child}
      yield item unless item.directory? || item.ncx?
    end
  end

  def itemWithId(identifier)
    @hash[identifier]
  end

  def itemWithHref(href)
    each {|item| return item if item.href == href}
    nil
  end
  
  def save(directory)
    src  = File.join(@root.uri.path, '.')
    dest = File.join(directory, @root.href)
    FileUtils.cp_r(src, dest)
  end

end