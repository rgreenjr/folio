class Manifest

  attr_accessor :root, :ncx

  def initialize(book)
    @hash  = {}
    @root = Item.new(nil, book.container.path, 'ROOT', 'directory', true)
    book.container.opfDoc.elements.each("/package/manifest/item") do |e|
      parent = @root
      parts = e.attributes["href"].split('/')
      parts.each_with_index do |part, index|
        break if index == (parts.size - 1)
        directory = parent.find(part)
        if directory == nil
          directory = Item.new(parent, part, "directory-#{part}", 'directory')
          parent << directory
        end
        parent = directory
      end
      item = Item.new(parent, parts.last, e.attributes["id"], e.attributes["media-type"])
      if item.ncx?
        @ncx = item
      else
        parent << item
        raise "Manifest item already exists with id=#{item.id}" if @hash[item.id]      
        @hash[item.id] = item
      end
    end
    raise "The NCX is missing." unless @ncx
  end

  def each(includeDirectories=false, &block)
    stack = [@root]
    while stack.size > 0
      item = stack.shift
      item.each {|child| stack << child}
      yield item unless item.directory? && !includeDirectories
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
  
  def move(item, index, parent)
    FileUtils.mv(item.path, File.join(parent.path, item.name))
    item.parent.delete(item)
    parent.insert(index, item)
  end

  def itemWithId(identifier)
    @hash[identifier]
  end
  
  def itemWithHref(href)
    current = @root
    parts = href.split('/')
    while !parts.empty? && current
      current = current.find(parts.shift)
    end
    current
  end
  
  def save(directory)
    each(true) {|item| item.save(directory)}
  end

end