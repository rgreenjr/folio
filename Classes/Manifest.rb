class Manifest
  
  attr_accessor :items, :base, :root

  def initialize(book)
    @hash  = {}
    @root = Item.new("file://#{book.container.root}", 'ROOT', 'ROOT')
    book.container.opfDoc.elements.each("/package/manifest/item") do |e|      
      parts = e.attributes["href"].split('/')
      parent = @root
      parts.each_with_index do |part, index|
        break if index == (parts.size - 1)
        directory = parent.find(part)
        if directory == nil
          directory = Item.new("#{parent.uri}/#{part}", part, 'directory')
          parent << directory
        end
        parent = directory
      end
      item = Item.new("#{parent.uri}/#{parts.last}", e.attributes["id"], e.attributes["media-type"])
      parent << item
      raise "Manifest item ids must be unique: #{item.id}" if @hash[item.id]      
      @hash[item.id] = item
    end
  end
  
  def [](index)
    @root.traverse(index).first
  end
  
  def itemWithId(identifier)
    @hash[identifier]
  end

end