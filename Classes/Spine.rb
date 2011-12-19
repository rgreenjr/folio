class Spine < DelegateClass(Array)

  def initialize(book=nil)
    @itemRefs = []
    super(@itemRefs)
    if book
      book.container.each_element("/package/spine/itemref") do |element|
        idref = element.attributes["idref"]
        linear = element.attributes["linear"]
        item = book.manifest.itemWithId(idref)
        raise "Spine item with idref \"#{idref}\" could not be found." unless item
        @itemRefs << ItemRef.new(item, linear)
      end
    end
  end
  
  def insert(index, item)
    index = -1 if index > size
    super
  end
  
  def move(itemRef, newIndex)
    return nil unless itemRef
    currentIndex = index(itemRef)
    return nil unless currentIndex
    delete_at(currentIndex)
    insert(newIndex, itemRef)
    currentIndex
  end
  
  def itemRefWithId(id)
    find { |itemRef| itemRef.id == id }
  end
  
  def itemRefsWithItem(item)
    select { |itemRef| itemRef.item.id == item.id }
  end

end