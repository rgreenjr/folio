class TextViewController

  attr_accessor :item, :textView, :webView

  def awakeFromNib
    scrollView = @textView.enclosingScrollView
    scrollView.verticalRulerView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
	
    # disable spell checking
    @textView.setEnabledTextCheckingTypes(0)
    @textView.delegate = self    
  end

  def item=(item)
    @item = item
    if @item && @item.editable?
      attributes = { NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      string = NSAttributedString.alloc.initWithString(@item.content, attributes:attributes)
      # rangePiointer = Pointer.new(NSRange.type)
      # @textView.layoutManager.characterRangeForGlyphRange(N, actualGlyphRange:actualGlyphRange)
      # point = @textView.enclosingScrollView.contentView.bounds.origin
      # p point
      # point.y += 250
      # p point
      # @textView.scrollPoint(point)
    else
      string = NSAttributedString.alloc.initWithString('')
    end
    @textView.textStorage.attributedString = string
  end
  
  def textView(tv, shouldChangeTextInRange:afcr, replacementString:rps)
    true
  end

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string		
    @webView.reload(self)
  end

end