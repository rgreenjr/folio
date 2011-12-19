class ItemRef

  PBOARD_TYPE = "ItemRefPboardType"

  attr_accessor :item
  
  # Indicates whether a spine item is considered primary (yes) or auxiliary (no). This enables 
  # Reading Systems to distinguish presentation of body content from supplementary content.
  attr_accessor :linear
  
  def initialize(item, linear='yes')
    @item = item
    @linear = linear
  end
  
  def idref
    @item.id
  end
  
  def referenceType
    @item.referenceType
  end
  
  def linear?
    @linear.nil? || @linear.downcase == 'yes'
  end
  
end
