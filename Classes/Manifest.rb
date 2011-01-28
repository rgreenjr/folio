class Manifest

  attr_accessor :root, :ncx
  
  def initialize(containerPath, book=nil)
    @itemsMap  = {}
    @containerPath = containerPath
    @root = Item.new(nil, @containerPath, 'ROOT', 'directory', true)
    if book.nil?
      @ncx = Item.new(@root, 'toc.ncx', 'toc.ncx', 'application/x-dtbncx+xml')
    else
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
        raise "The resource file \"#{item.href}\" could not be found." unless File.exist?(item.path)
        if item.ncx?
          @ncx = item
        else
          insert(-1, item, parent)
        end
      end
      raise "A navigation NCX file wasn't specified in the manifest." unless @ncx
      self.sort
    end
  end
  
  def addFile(filepath, parent, index)
    name = File.basename(filepath)
    return nil if parent.childWithName(name)
    item = Item.new(parent, name, generateUniqueID(name))
    item.content = File.read(filepath)
    parent.insert(index, item)    
    item
  end
  
  def insert(index, item, parent)
    unless item.directory?
      raise "A resource with ID \"#{item.id}\" already exists in the manifest." if @itemsMap[item.id]
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
  
  def select(&block)
    items = []
    each do |item|
      items << item if yield item
    end
    items
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
    href = href.gsub(@containerPath + "/", '')
    current = @root
    parts = href.split('/')
    while !parts.empty? && current
      current = current.childWithName(parts.shift)
    end
    current
  end
  
  def changeItemId(item, newID)
    return nil if itemWithId(newID)
    @itemsMap[item.id] = nil
    oldID = item.id
    item.id = newID
    @itemsMap[item.id] = item
    oldID
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
  
  private
  
  def generateUniqueID(name)
    name = name.stringByDeletingPathExtension
    i = 1
    while itemWithId(name)
      i += 1
      name = "#{name}-#{i}"
    end
    name
  end

end
