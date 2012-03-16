class Manifest

  attr_accessor :root
  attr_accessor :ncx

  def self.load(package)
    manifest = Manifest.new(package)

    package.each("manifest/item") do |element|
      parent = manifest.root
      parts = element.attributes["href"].split('/')
      parts.each_with_index do |part, index|
        break if index == (parts.size - 1)
        directory = parent.childWithName(part)
        if directory == nil
          directory = Item.new(parent, part, nil, Media::DIRECTORY)
          parent << directory
        end
        parent = directory
      end

      item = Item.new(parent, parts.last, element.attributes["id"], element.attributes["media-type"])

      # raise if item doesn't exist
      unless File.exist?(item.absolutePath)
        raise "The manifest item \"#{item.href}\" could not be found."
      end

      # raise if item isn't readable
      unless File.readable?(item.absolutePath)
        raise "You do not have permission to access the manifest item \"#{item.href}\"."
      end

      # check item is NCX otherwise append to end
      if item.ncx?
        manifest.ncx = item
      else
        manifest.insert(-1, item, parent)
      end
    end

    # an NCX file is required, so raise if one wasn't found
    raise "A navigation NCX file wasn't specified in the manifest." unless manifest.ncx

    manifest.sort

    manifest
  end

  def initialize(package)
    @package = package
    @root = Item.new(nil, @package.absoluteDirectory, 'ROOT', Media::DIRECTORY, true)
    @ncx = Item.new(@root, 'toc.ncx', 'toc.ncx', Media::NCX)
    @itemsMap  = {}
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
    FileUtils.mv(item.absolutePath, File.join(parent.absolutePath, item.name))
    item.parent.delete(item)
    parent.insert(index, item)
  end

  def itemWithId(identifier)
    @itemsMap[identifier]
  end

  def itemWithHref(href)
    href = @package.makePathRelative(href)    
    current = @root
    parts = href.split('/')
    while !parts.empty? && current
      current = current.childWithName(parts.shift)
    end
    current
  end

  def changeItemId(item, newID)
    # check if newID is already being used
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

  def eachSpineableItem
    each do |item|
      yield item if item.spineable?
    end
  end

  def totalIssueCount
    itemsWithIssues.inject(0) { |sum, item| sum += item.issueCount }
  end

  def clearIssues
    each { |item| item.clearIssues }
  end

  def sort
    @root.sort
  end

  def saveAllItems(directoryPath)
    each(true) {|item| item.saveToDirectory(directoryPath)}
  end


  def validate
    each do |item|
      validateAnchorNodes(item)
      validateImageNodes(item)
    end
  end

  def size
    count = 0
    each { count += 1 }
    count
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

  def validateAnchorNodes(item)
    item.anchorNodes.each do |node|
      href = node.attributeForName("href").stringValue
      unless NSURL.URLWithString(href).remote?
        # strip fragment before lookup
        href, fragment = href.split('#')
        
        # ignore self-referencing links with just a fragment 
        next if href.blank? && !fragment.blank?
        
        # expand src incase '.' or '..' are used
        expandedPath = File.expand_path(href, File.dirname(item.absolutePath))
        unless itemWithHref(expandedPath)
          item.addIssue(Issue.new("The item \"#{href}\" is referenced but doesn't exist."))
        end
      end
    end
  end

  def validateImageNodes(item)
    item.imageNodes.each do |node|
      src = node.attributeForName("src").stringValue
      # expand src incase '.' or '..' are used
      expandedPath = File.expand_path(src, File.dirname(item.absolutePath))
      unless itemWithHref(expandedPath)
        item.addIssue(Issue.new("The image \"#{src}\" is referenced but doesn't exist."))
      end
    end
  end

end
