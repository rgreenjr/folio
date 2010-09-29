class TextViewController

  attr_accessor :item, :textView, :webView

  def awakeFromNib
    scrollView = @textView.enclosingScrollView
    scrollView.verticalRulerView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true

    @textView.delegate = self
    @textView.setEnabledTextCheckingTypes(0)
    
    @highlighter = Highlighter.new(@textView)
  end

  def item=(item)
    return if item == @item
    @item = item
    if @item && @item.editable?
      attributes = { NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      string = NSAttributedString.alloc.initWithString(@item.content, attributes:attributes)
    else
      string = NSAttributedString.alloc.initWithString('')
    end
    @textView.textStorage.attributedString = string
  end

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string
    @webView.reload(self)
  end
  
  def insertionPoint
    @textView.selectedRanges.first.rangeValue.location
  end

  def replace(range, replacement)
    if @textView.shouldChangeTextInRange(range, replacementString:replacement)
      @textView.textStorage.beginEditing    
      @textView.textStorage.replaceCharactersInRange(range, withString:replacement)
      @textView.textStorage.endEditing
      @textView.didChangeText
    else
      NSBeep()
    end
  end
  
end
