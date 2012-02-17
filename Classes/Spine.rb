class Spine

 include Enumerable

  attr_reader :itemRefs
  
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
  end

  def each(&block)
    @itemRefs.each { |itemRef| yield itemRef } 
  end

  def empty?
    @itemRefs.empty?
  end
  
  def size
    @itemRefs.size
  end

  def insert(index, item)
    index = -1 if index > size
    @itemRefs.insert(index, item)
  end

  def <<(itemRef)
    @itemRefs << itemRef if itemRef
  end

  def [](index)
    @itemRefs[index] 
  end
 
  def index(itemRef)
    @itemRefs.index(itemRef)     
  end  

  def delete_at(index)
    @itemRefs.delete_at(index)    
  end

  def move(itemRef, newIndex)
    return nil unless itemRef
    currentIndex = @itemRefs.index(itemRef)
    return nil unless currentIndex
    @itemRefs.delete_at(currentIndex)
    @itemRefs.insert(newIndex, itemRef)
    currentIndex
  end
  
  def itemRefWithId(id)
    @itemRefs.find { |itemRef| itemRef.idref == id }
  end
  
  def itemRefsWithItem(item)
    @itemRefs.select { |itemRef| itemRef.idref == item.id }
  end
  
end