class Spine < DelegateClass(Array)

  def initialize(book)
    @items = []
    super(@items)
    book.container.opfDoc.elements.each("/package/spine/itemref") do |element|
      idref = element.attributes["idref"]
      item = book.manifest.itemWithId(idref)
      raise "Spine item is missing: idref=#{idref}" unless item
      @items << item
    end
  end

end