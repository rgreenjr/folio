class TextViewController

  attr_accessor :item, :textView, :webView

  def awakeFromNib
    # scrollView = @textView.enclosingScrollView
    # scrollView.verticalRulerView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    # scrollView.hasHorizontalRuler = false
    # scrollView.hasVerticalRuler = true
    # scrollView.rulersVisible = true

    @textView.delegate = self
    @textView.setEnabledTextCheckingTypes(0)

    # @highlighter = Highlighter.new(@textView)
  end

  def item=(item)
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

  def selectWord(sender)  
  end

  def selectLine(sender)
    paragraphRange = @textView.textStorage.string.paragraphRangeForRange(selectedRange)
    @textView.setSelectedRange(paragraphRange)
  end

  def selectEnclosingBrackets(sender)
  end

  def insertCloseTag(sender)
    empty_tags = "br|hr|meta|link|base|link|meta|img|embed|param|area|col|input|frame|isindex"
    
    before = /(.){#{caretLocation}}/m.match(@textView.string)[0]

    before.gsub!(/<[^>]+\/\s*>/i, '')

    # remove all self-closing tags
    before.gsub!(/<(#{empty_tags})\b[^>]*>/i, '')

    # remove all comments
    before.gsub!(/<!--.*?-->/m, '')

    stack = []
    before.scan(/<\s*(\/)?\s*(\w[\w:-]*)[^>]*>/) do |match|
      if match[0].nil? then
        stack << match[1]
      else
        until stack.empty? do
          close_tag = stack.pop
          break if close_tag == match[1]
        end
      end
    end

    if stack.empty?
      NSBeep()
    else
      replace(NSRange.new(caretLocation, 0), "</#{stack.pop}>")
    end
  end

  def strongSelectedText(sender)
    replace(selectedRange, "<strong>#{selectedText}</strong>")
  end

  def emphasizeSelectedText(sender)
    replace(selectedRange, "<em>#{selectedText}</em>")
  end

  def stripHTMLTagsFromSelection(sender)
    tmp_file = Tempfile.new('folio-tmp-file')
    File.open(tmp_file, "w") {|f| f.print selectedText}
    replace(selectedRange, `php -r 'echo strip_tags( file_get_contents("#{tmp_file.path}") );'`)
    tmp_file.delete
  end

  def paragraphSelectedLines(sender)
    replace(selectedRange, selectedText.split.map {|line| "<p>#{line}<p/>\n"}.join)
  end

  private

  def selectedRange
    @textView.selectedRange
  end

  def selectedText
    @textView.string.substringWithRange(selectedRange)
  end

  def caretLocation
    selectedRange.location
  end

end
