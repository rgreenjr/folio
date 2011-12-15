class TextViewController < NSViewController

  attr_accessor :bookController
  attr_accessor :webViewController

  attr_accessor :item
  attr_accessor :lineNumberView

  def awakeFromNib
    @textAttributes = { NSFontAttributeName => PreferencesController.sharedPreferencesController.editorFont }  

    scrollView = view.enclosingScrollView
    @lineNumberView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.verticalRulerView = @lineNumberView
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
    
    view.delegate = self
    view.setEnabledTextCheckingTypes(0)

    # register to receive preference change notifications
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('preferencesDidChange:'), name:'PreferencesDidChange', object:nil)

    # @highlighter = Highlighter.new(view)
  end
  
  def preferencesDidChange(notification)
    @textAttributes = { NSFontAttributeName => notification.object.editorFont }
    self.item = @item # reload item to force font change
  end

  def item=(item)
    @item = item    
    if @item && @item.editable?
      @lineNumberView.issueHash = @item.issueHash      
      string = NSAttributedString.alloc.initWithString(@item.content, attributes:@textAttributes)
    else
      @lineNumberView.clearIssues
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
    @gotoLineController.showWindowWithTarget(self)
  end
  
  def gotoLineNumber(lineNumber)
    if lineNumber > 0
      @lineNumberView.gotoLine(lineNumber)
      view.window.makeFirstResponder(view)
    end
  end
  
  def selectLineNumber(lineNumber)
    if lineNumber > 0
      @lineNumberView.selectLineNumber(lineNumber)
    end
  end

  def textDidChange(notification)
    return unless @item
    @item.content = view.textStorage.string
    @webViewController.reload(self)

    # update document change count so user will be prompted to save book
    @bookController.document.updateChangeCount(NSSaveOperation)    
  end
  
  def undoManagerForTextView(textView)
    @bookController.tabbedViewController.undoManagerForItem(@item)
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

  def selectCurrentLine(sender)
    paragraphRange = view.textStorage.string.paragraphRangeForRange(selectedRange)
    view.setSelectedRange(paragraphRange)
  end

  def selectEnclosingBrackets(sender)
  end

  def uppercaseSelectedText(sender)
    modifySelection {|text| text.upcase}
  end

  def lowercaseSelectedText(sender)
    modifySelection {|text| text.downcase}
  end

  def titlecaseSelectedText(sender)
    modifySelection {|text| text.titleize.downcasePrepositions }
  end

  def strongifySelectedText(sender)
    modifySelection {|text| "<strong>#{text}</strong>" }
  end

  def emphasizeSelectedText(sender)
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

  def stripTagsFromSelectedText(sender)
    tmp = Tempfile.new('folio-tmp-file')
    text = selectedText
    text = view.string if text.size == 0
    File.open(tmp, "w") {|f| f.print text}
    replace(NSRange.new(0, text.size), `php -r 'echo strip_tags( file_get_contents("#{tmp.path}") );'`)
    tmp.delete
  end

  def reindentText(sender)
    tmp = Tempfile.new('folio-tmp-file')
    text = view.string
    File.open(tmp, "w") { |f| f.print text }
    output = `xmllint --format #{tmp.path} 2>&1`
    @item.clearIssues
    if $?.success?
      replace(NSRange.new(0, text.length), output)
    else
      output.gsub!(tmp.path + ':', 'Line ')
      output.gsub!("^", '')
      output.split(/\n/).each do |line|
        if line =~ /^Line ([0-9]+): (.*)/
          lineNumber = $1.to_i - 1
          message = $2.gsub("parser error : ", "")
          issue = Issue.new(message, lineNumber)
          @item.addIssue(issue) 
        end
      end
      # goto the first issue
      @item.issues.each do |issue|
        gotoLineNumber(issue.lineNumber + 1)
        break
      end
    end
    tmp.delete
    @lineNumberView.setNeedsDisplay true
    NSNotificationCenter.defaultCenter.postNotificationName("ItemIssuesDidChange", object:@bookController)
  end

  def paragraphSelectedLines(sender)
    replace(selectedRange, selectedText.split.map {|line| "<p>#{line}<p/>\n"}.join)
  end

  def validateUserInterfaceItem(interfaceItem)
    return false unless @item
    case interfaceItem.action
    when :"strongify:", :"emphasize:", :"paragraphSelectedLines:", :"uppercase:", :"lowercase:", :"titlecase:", :"stripTags:"
      selectedRange.length > 0
    when :"formatMarkup:"
      item.formatable?
    else
      true
    end
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
