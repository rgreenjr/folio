class Spine < DelegateClass(Array)
  
  def self.load(package)
    spine = Spine.new
    package.each("spine/itemref") do |element|
      idref = element.attributes["idref"]
      linear = element.attributes["linear"]
      item = package.manifest.itemWithId(idref)
      raise "Could not find spine itemref with idref \"#{idref}\"." unless item
      spine << ItemRef.new(item, linear)
    end
    spine
  end

  def initialize
    @itemRefs = []
    super(@itemRefs)
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
    find { |itemRef| itemRef.idref == id }
  end
  
  def itemRefsWithItem(item)
    select { |itemRef| itemRef.idref == item.id }
  end

end