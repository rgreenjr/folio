class ItemRef
  
  extend Forwardable
  
  attr_accessor :item, :linear
  
  def initialize(item, linear=nil)
    @item, @linear = item, linear
  end
  
  def_delegator :@item, :id, :id
  def_delegator :@item, :name, :name
  def_delegator :@item, :mediaType, :mediaType
  def_delegator :@item, :size, :size
  def_delegator :@item, :editable?, :editable?
  def_delegator :@item, :flowable?, :flowable?
  def_delegator :@item, :imageable?, :imageable?
  def_delegator :@item, :renderable?, :renderable?
  def_delegator :@item, :markerHash, :markerHash
  def_delegator :@item, :content, :content
  def_delegator :@item, :url, :url
  def_delegator :@item, :href, :href
  def_delegator :@item, :edited?, :edited?
  def_delegator :@item, :clearMarkers, :clearMarkers
  def_delegator :@item, :content=, :content=

end
