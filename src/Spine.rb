class Spine

  def initialize(book)
    @items = []

    # ncxID = book.container.opfDoc.elements["/package/spine"].attributes["toc"]
    # raise "An NCX file is not speicifed." unless ncxID
    
    raise "The NCX file is missing." unless book.manifest.ncx

    book.container.opfDoc.elements.each("/package/spine/itemref") do |element|
      idref = element.attributes["idref"]
      item = book.manifest.itemWithId(idref)
      raise "Spine item is missing: idref=#{idref}" unless item
      @items << item
    end
  end

  def size
    @items.size
  end

  def first
    @items.first
  end

  def each(&block)
    @items.each(&block)
  end

  def <<(item)
    @item << item
  end

  def [](index)
    @items[index]
  end

end