class ItemRef

  attr_accessor :item, :linear, :id, :type
  
  def initialize(item, linear=nil)
    @item, @linear, @id = item, linear, UUID.create
  end
  
  def linear?
    @linear.nil? || @linear.downcase == 'yes'
  end
  
end
