class Manifest

  attr_accessor :root, :ncx
  
  def initialize(container)
    @container = container
    
    @itemsMap  = {}

    # create the root item
    @root = Item.new(nil, @container.absolutePath, 'ROOT', Media::DIRECTORY, true)
    
    if !@container.hasOPFDoc?
      @ncx = Item.new(@root, 'toc.ncx', 'toc.ncx', 'application/x-dtbncx+xml')
    else
      @container.each_element("/package/manifest/item") do |e|
        parent = @root
        parts = e.attributes["href"].split('/')
        parts.each_with_index do |part, index|
          break if index == (parts.size - 1)
          directory = parent.childWithName(part)
          if directory == nil
            directory = Item.new(parent, part, nil, Media::DIRECTORY)
            parent << directory
          end
          parent = directory
        end
        item = Item.new(parent, parts.last, e.attributes["id"], e.attributes["media-type"])
        
        # raise if item isn't readable
        unless File.readable?(item.path)
          raise "You do not have permission to open the resource file \"#{item.href}\"."
        end
        
        # raise if item doesn't exist
        unless File.exist?(item.path)
          raise "The resource file \"#{item.href}\" could not be found."
        end
        
        # check item is NCX otherwise append to end
        if item.ncx?
          @ncx = item
        else
          insert(-1, item, parent)
        end
      end

      # an NCX file is required, so raise if one wasn't found
      raise "A navigation NCX file wasn't specified in the manifest." unless @ncx
      
      self.sort
    end
  end
  
  def addFile(filepath, parent, index, replace=false)
    name = File.basename(filepath)
    item = parent.childWithName(name)
    if item
      unless replace
        raise "A file named \"#{name}\" already exists in the directory."
      end
      item.content = File.read(filepath)
    else
      item = Item.new(parent, name, generateUniqueID(name))
      item.content = File.read(filepath)
      insert(index, item, parent)    
    end
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
    href = @container.relativePathFor(href)
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
  
  def itemsWithIssues
    select { |item| item.hasIssues? }
  end
  
  def totalIssueCount
    itemsWithIssues.inject(0) { |sum, item| sum += item.issueCount }
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
