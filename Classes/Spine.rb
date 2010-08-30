class Spine

  attr_accessor :items, :ncx

  def initialize(book)
    @items = []

    ncxId = book.container.opfDoc.elements["/package/spine"].attributes["toc"]
    raise "An NCX file is not speicifed in the spine as required." unless ncxId
    @ncx = book.manifest.itemWithId(ncxId)
    raise "The NCX file is missing: id=#{ncxId}" unless @ncx

    book.container.opfDoc.elements.each("/package/spine/itemref") do |element|
      item = book.manifest.itemWithId(element.attributes["idref"])
      raise "Spine item is missing: #{element.attributes["idref"]}" unless item
      @items << item
    end
  end

  def ncxDoc
    @ncxDoc ||= REXML::Document.new(@ncx.content)
  end

  def size
    @items.size
  end

  def first
    @items.first
  end

  def each
    @items.each {|i| yield i} 
  end

  def <<(item)
    @item << item
  end

  def [](index)
    @items[index]
  end

end