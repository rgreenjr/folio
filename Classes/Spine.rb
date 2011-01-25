class Spine < DelegateClass(Array)

  def initialize(book=nil)
    @itemrefs = []
    super(@itemrefs)
    if book
      book.container.opfDoc.elements.each("/package/spine/itemref") do |element|
        idref = element.attributes["idref"]
        linear = element.attributes["linear"]
        item = book.manifest.itemWithId(idref)
        raise "Spine item with idref \"#{idref}\" could not be found." unless item
        @itemrefs << ItemRef.new(item, linear)
      end
    end
  end
  
  def insert(index, item)
    index = -1 if index > size
    super
  end
  
  def itemRefWithId(id)
    find { |itemref| itemref.id == id }
  end

end