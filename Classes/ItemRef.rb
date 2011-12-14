class ItemRef

  PBOARD_TYPE = "ItemRefPboardType"

  attr_accessor :item
  
  # Indicates whether a spine item is considered primary (yes) or auxiliary (no). This enables 
  # Reading Systems to distinguish presentation of body content from supplementary content.
  attr_accessor :linear
  
  attr_accessor :type
  
  def initialize(item, linear='yes')
    @item, @linear = item, linear
  end
  
  def idref
    @item.id
  end
  
  def linear?
    @linear.nil? || @linear.downcase == 'yes'
  end
  
end
