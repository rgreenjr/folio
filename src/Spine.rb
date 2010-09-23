class Spine

  def initialize(book)
    @items = []
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

  def each(&block)
    @items.each(&block)
  end

  def <<(item)
    @item << item
  end

  def [](index)
    @items[index]
  end

  def delete_at(index)
    @items.delete_at(index)
  end

  def insert(index, item)
    index = -1 if index > size
    @items.insert(index, item)
  end

end