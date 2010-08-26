class TextViewController
  
  attr_accessor :bookController, :textView, :item
  
  def refresh
    str = (@item.text?) ? @item.content : ''
    @textView.textStorage.attributedString = NSAttributedString.alloc.initWithString(str)
    @textView.richText = false
  end

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string
    refresh
  end

end