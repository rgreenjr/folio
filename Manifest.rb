class Manifest
  
  attr_accessor :items, :base

  def initialize(book)
    @items = []
    book.container.opfDoc.elements.each("/package/manifest/item") do |e|
      @items << Item.new(book.container.root, e.attributes["href"], e.attributes["id"], e.attributes["media-type"])
    end
  end

  def size
    @items.size
  end
  
  def each
   @items.each {|i| yield i} 
  end
  
  def [](index)
    @items[index]
  end
  
  def itemWithHref(href)
    href = URI.parse(href).path
    each {|i| return i if i.href == href}
    nil
  end

  def itemWithId(id)
    each {|i| return i if i.id == id}
    nil
  end
  
end