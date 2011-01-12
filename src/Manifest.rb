class Manifest

  attr_accessor :root, :ncx

  def initialize(book=nil)
    @itemsMap  = {}
    if book.nil?
      @root = Item.new(nil, 'OEBPS', 'ROOT', 'directory', true)
      @ncx = Item.new(@root, 'toc.ncx', 'toc.ncx', 'application/x-dtbncx+xml')
    else
      @book = book
      @root = Item.new(nil, book.container.path, 'ROOT', 'directory', true)
      book.container.opfDoc.elements.each("/package/manifest/item") do |e|
        parent = @root
        parts = e.attributes["href"].split('/')
        parts.each_with_index do |part, index|
          break if index == (parts.size - 1)
          directory = parent.childWithName(part)
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
          insert(-1, item, parent)
        end
      end
      raise "An NCX was not specified in the manifest." unless @ncx
      self.sort
    end
  end
  
  def addFile(filepath, parent, index)
    name = File.basename(filepath)
    return nil if parent.childWithName(name)
    item = Item.new(parent, name)
    item.content = File.read(filepath)
    parent.insert(index, item)    
    item
  end
  
  def insert(index, item, parent)
    unless item.directory?
      raise "A manifest item already exists with the id=#{item.id}" if @itemsMap[item.id]
    end
    @itemsMap[item.id] = item
    parent.insert(index, item)
  end
  
  def delete(item)
    parent = item.parent
    NSWorkspace.sharedWorkspace.performSelector(:"recycleURLs:completionHandler:", withObject:[item.url], withObject:nil)
    parent.delete_at(item.parent.index(item))
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
    @itemsMap[identifier]
  end
  
  def itemWithHref(href)
    href = @book.container.relativePathFor(href)
    current = @root
    parts = href.split('/')
    while !parts.empty? && current
      current = current.childWithName(parts.shift)
    end
    current
  end
  
  def sort
    @root.sort
  end

  def save(directory)
    each(true) {|item| item.saveToDirectory(directory)}
  end
  
  def to_s
    buffer = "@manifest = {\n"
    @itemsMap.each do |id, item|
      buffer << "  id=#{id} => href=#{item.href}\n"
    end
    buffer << "}"
    buffer
  end
  
end