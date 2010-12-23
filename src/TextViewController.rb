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
  
  def toggleRuler(sender)
    @textView.enclosingScrollView.rulersVisible = !@textView.enclosingScrollView.rulersVisible
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

  def uppercase(sender)
    modifySelection {|text| text.upcase}
  end

  def lowercase(sender)
    modifySelection {|text| text.downcase}
  end

  def titlecase(sender)
    modifySelection {|text| text.titleize.downcasePrepositions }
  end

  def strongify(sender)
    modifySelection {|text| "<strong>#{text}</strong>" }
  end

  def emphasize(sender)
    modifySelection {|text| "<em>#{text}</em>" }
  end

  def insertCloseTag(sender)
    emptyTags = "br|hr|meta|link|base|link|meta|img|embed|param|area|col|input|frame|isindex"

    text = @textView.string.substringToIndex(caretLocation)

    # remove all self-closing tags
    text = text.gsub(/<[^>]+\/\s*>/i, '')

    # remove all empty tags
    text.gsub!(/<(#{emptyTags})\b[^>]*>/i, '')

    # remove all comments
    text.gsub!(/<!--.*?-->/m, '')

    stack = []
    text.scan(/<\s*(\/)?\s*(\w[\w:-]*)[^>]*>/) do |match|
      if match[0].nil? then
        stack << match[1]
      else
        until stack.empty? do
          closeTag = stack.pop
          break if closeTag == match[1]
        end
      end
    end

    if stack.empty?
      NSBeep()
    else
      replace(NSRange.new(caretLocation, 0), "</#{stack.pop}>")
    end
  end

  def stripTags(sender)
    tmp = Tempfile.new('folio-tmp-file')
    text = selectedText
    text = @textView.string if text.size == 0
    File.open(tmp, "w") {|f| f.print text}
    replace(NSRange.new(0, text.size), `php -r 'echo strip_tags( file_get_contents("#{tmp.path}") );'`)
    tmp.delete
  end

  def tidy(sender)
    tmp = Tempfile.new('folio-tmp-file')
    text = @textView.string
    File.open(tmp, "w") { |f| f.print text }
    output = `xmllint --format #{tmp.path} 2>&1`
    if $?.success?
      replace(NSRange.new(0, text.length), output)
    else
      output.gsub!(tmp.path + ':', 'Line ')
      output.gsub!("^", '')
      showValidationAlert(output)
    end
    tmp.delete
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

  def modifySelection(&block)
    range = selectedRange
    text = selectedText
    modifedText = yield(text)
    replace(range, modifedText)
    modifiedRange = NSRange.new(range.location, range.length + (modifedText.size - text.size))
    @textView.setSelectedRange(modifiedRange)
  end

  def showValidationAlert(message)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "Validation Failed"
    alert.informativeText = message
    alert.runModal
  end

end
