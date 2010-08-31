class TextViewController

  attr_accessor :item, :textView, :webView

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
  
  def textView(tv, shouldChangeTextInRange:afcr, replacementString:rps)
    p afcr
    # puts "textView(tv, shouldChangeTextInRange:#{afcr}, replacementString:#{rps})"
    @changedText = rps
  end

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string		
    @webView.reload(self)
    # @webView.replaceSelectionWithText @changedText
  end

end