class TextViewController

  attr_accessor :item, :textView, :webView

  def awakeFromNib
    # blue = NSDictionary.alloc.initWithObjectsAndKeys(NSFont.userFixedPitchFontOfSize(11.0), NSFontAttributeName, NSColor.blueColor, NSForegroundColorAttributeName, nil)
    # string = NSMutableAttributedString.alloc.initWithString("Hello World", attributes:blue)
    # @textView.textStorage.attributedString = string
    # 
    # range = NSMakeRange(0, 5)
    # 
    # red = NSDictionary.alloc.initWithObjectsAndKeys(NSFont.userFixedPitchFontOfSize(18.0), NSFontAttributeName, NSColor.redColor, NSForegroundColorAttributeName, nil)
    # string = NSMutableAttributedString.alloc.initWithString("Hello", attributes:red)
    # @textView.textStorage.replaceCharactersInRange(range, withAttributedString:string)

    scrollView = @textView.enclosingScrollView
    scrollView.verticalRulerView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
	
    @textView.delegate = self
  end

  def item=(item)
    @item = item
    if @item && @item.editable?
      string = NSAttributedString.alloc.initWithString(@item.content)
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