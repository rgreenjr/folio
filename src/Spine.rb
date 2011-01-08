class Spine < DelegateClass(Array)

  def initialize(book=nil)
    @items = []
    super(@items)
    
    return unless book
    
    book.container.opfDoc.elements.each("/package/spine/itemref") do |element|
      idref = element.attributes["idref"]
      item = book.manifest.itemWithId(idref)
      raise "Spine item is missing: idref=#{idref}" unless item
      @items << item
    end
  end
  
  def insert(index, item)
    super unless include?(item)
  end

end