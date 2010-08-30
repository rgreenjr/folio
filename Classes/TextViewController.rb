class TextViewController

  attr_accessor :textView, :item

  def awakeFromNib
    @textView.delegate = self
  end

  def item=(item)
    @item = item
    if @item && @item.editable?
      string = NSAttributedString.alloc.initWithString(@item.content)
    else
      string = NSAttributedString.alloc.initWithString('')
    end
    @textView.textStorage.attributedString = string
    @textView.richText = false
  end

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string
  end

end