class TextViewController < NSViewController

  attr_accessor :item, :webViewController, :tabViewController

  def awakeFromNib
    scrollView = view.enclosingScrollView
    @lineNumberView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.verticalRulerView = @lineNumberView
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
    
    view.delegate = self
    view.setEnabledTextCheckingTypes(0)

    # @highlighter = Highlighter.new(view)
  end

  def item=(item)
    @item = item    
    if @item && @item.editable?
      @lineNumberView.markerHash = @item.markerHash      
      attributes = { NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      string = NSAttributedString.alloc.initWithString(@item.content, attributes:attributes)
    else
      @lineNumberView.clearMarkers
      string = NSAttributedString.alloc.initWithString('')
    end
    view.textStorage.attributedString = string
  end
  
  def toggleLineNumbers(sender)
    if sender.title == 'Hide Line Numbers'
      sender.title = 'Show Line Numbers'
      view.enclosingScrollView.rulersVisible = false
    else
      sender.title = 'Hide Line Numbers'
      view.enclosingScrollView.rulersVisible = true
    end
  end
  
  def showGotoLineWindow(sender)
    @gotoLineController ||= GotoLineController.alloc.init
    @gotoLineController.window
    @gotoLineController.showWindowWithTarget(self)
  end
  
  def gotoLineNumber(lineNumber)
    if lineNumber > 0
      @lineNumberView.gotoLine(lineNumber)
      view.window.makeFirstResponder(view)
    end
  end

  def textDidChange(notification)
    return unless @item
    @item.content = view.textStorage.string
    @webViewController.reload(self)
  end
  
  def undoManagerForTextView(textView)
    @tabViewController.undoManagerForItem(@item)
  end

  def replace(range, replacement)
    if view.shouldChangeTextInRange(range, replacementString:replacement)
      view.textStorage.beginEditing    
      view.textStorage.replaceCharactersInRange(range, withString:replacement)
      view.textStorage.endEditing
      view.didChangeText
    else
      NSBeep()
    end
  end

  def selectWord(sender)
  end

  def selectLine(sender)
    paragraphRange = view.textStorage.string.paragraphRangeForRange(selectedRange)
    view.setSelectedRange(paragraphRange)
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

    text = view.string.substringToIndex(caretLocation)

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
    text = view.string if text.size == 0
    File.open(tmp, "w") {|f| f.print text}
    replace(NSRange.new(0, text.size), `php -r 'echo strip_tags( file_get_contents("#{tmp.path}") );'`)
    tmp.delete
  end

  def formatMarkup(sender)
    tmp = Tempfile.new('folio-tmp-file')
    text = view.string
    File.open(tmp, "w") { |f| f.print text }
    output = `xmllint --format #{tmp.path} 2>&1`
    @item.clearMarkers
    if $?.success?
      replace(NSRange.new(0, text.length), output)
    else
      output.gsub!(tmp.path + ':', 'Line ')
      output.gsub!("^", '')
      output.split(/\n/).each do |line|
        if line =~ /^Line ([0-9]+): (.*)/
          lineNumber = $1.to_i - 1
          message = $2.gsub("parser error : ", "")
          marker = LineNumberMarker.alloc.initWithRulerView(@lineNumberView, lineNumber:lineNumber, message:message)
          @item.addMarker(marker) 
        end
      end
      # goto the first marker
      @item.markers.each do |marker|
        gotoLineNumber(marker.lineNumber + 1)
        break
      end
    end
    tmp.delete
    @lineNumberView.setNeedsDisplay true
  end

  def paragraphSelectedLines(sender)
    replace(selectedRange, selectedText.split.map {|line| "<p>#{line}<p/>\n"}.join)
  end

  def validateUserInterfaceItem(menuItem)
    @item != nil
  end
  
  def textView(view, menu:menu, forEvent:event, atIndex:charIndex)
    unsupported = menu.itemArray.select { |item| unsupportedMenuTitles.include?(item.title) }
    unsupported.each { |item| menu.removeItem(item) }
    menu
  end
  
  private
  
  def selectedRange
    view.selectedRange
  end

  def selectedText
    view.string.substringWithRange(selectedRange)
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
    view.setSelectedRange(modifiedRange)
  end
  
  def unsupportedMenuTitles
    @unsupportedMenuTitles ||= ["Spelling and Grammar", "Transformations", "Substitutions"]
  end

end
