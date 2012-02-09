class SourceViewController < NSViewController

  attr_reader   :bookController
  attr_accessor :webViewController
  attr_accessor :item
  attr_accessor :lineNumberView

  def awakeFromNib
    scrollView = view.enclosingScrollView
    @lineNumberView = LineNumberRuler.alloc.initWithScrollView(scrollView)
    scrollView.verticalRulerView = @lineNumberView
    scrollView.hasHorizontalRuler = false
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
    
    # make textView use integrated search/replace bar
    view.usesFindBar = true
    
    view.delegate = self
    view.setEnabledTextCheckingTypes(0)

    @syntaxHighlighter = SyntaxHighlighter.new(view)
    
    @selectedRangeHash = {}
    
    # set user font and background color
    processUserPreferences(PreferencesController.sharedPreferencesController)
        
    # register to receive preference change notifications
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"preferencesDidChange:", 
      name:'PreferencesDidChange', object:nil)
  end
  
  def bookController=(controller)
    @bookController = controller
  end
  
  def preferencesDidChange(notification)
    preferenceController = notification.object
    processUserPreferences(preferenceController)
    @syntaxHighlighter.processUserPreferences(preferenceController) if @syntaxHighlighter
    self.item = @item # reload item to force font change
  end
  
  def processUserPreferences(preferenceController)    
    @textAttributes = { NSFontAttributeName => preferenceController.font }
    view.backgroundColor = preferenceController.backgroundColor
    view.insertionPointColor = preferenceController.caretColor
    view.selectedTextAttributes = { 
      NSFontAttributeName => preferenceController.font,
      NSBackgroundColorAttributeName => preferenceController.selectionColor
    }
  end

  def item=(item)
    
    return if item == @item
      
    # record the currently selected text range
    storeSelectedRange(@item)

    @item = item
    if @item && @item.textual?
      @lineNumberView.item = @item
      @syntaxHighlighter.mediaType = @item.mediaType if @syntaxHighlighter
      string = NSAttributedString.alloc.initWithString(@item.content, attributes:@textAttributes)
    else
      @lineNumberView.item = nil
      string = NSAttributedString.alloc.initWithString('')
    end
    view.textStorage.attributedString = string
    
    # restore previous selected text range
    restoreSelectedRange(@item)
  end
  
  def toggleLineNumbers(sender)
    if view.enclosingScrollView.rulersVisible
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
      if match[0].nil?
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
    tmp = Tempfile.new('me.folioapp.striptags')
    begin
      text = selectedText
      text = view.string if text.size == 0
      File.open(tmp, "w") {|f| f.print text}
      replace(NSRange.new(0, text.size), `php -r 'echo strip_tags( file_get_contents("#{tmp.path}") );'`)
    ensure
      tmp.close
      tmp.unlink
    end
  end

  def reformatText(sender)
    @item.clearIssues
    formattedText, issues = XMLLint.format(view.string, @item.mediaType)
    if issues.empty?
      replace(NSRange.new(0, view.string.length), formattedText)
      @lineNumberView.setNeedsDisplay(true)
      NSNotificationCenter.defaultCenter.postNotificationName("ItemIssuesDidChange", object:@bookController)
      view.window.makeFirstResponder(view)
      view.selectedRange = NSMakeRange(0, 0)
    else
      issues.each { |issue| @item.addIssue(issue) }
      gotoLineNumber(@item.issues.first.lineNumber)
    end
  end

  def paragraphSelectedLines(sender)
    replace(selectedRange, selectedText.split.map {|line| "<p>#{line}<p/>\n"}.join)
  end

  def validateUserInterfaceItem(interfaceItem)
    return false unless @item && visible?
    case interfaceItem.action
    when :"strongifySelectedText:", :"emphasizeSelectedText:", :"paragraphSelectedLines:", 
         :"uppercaseSelectedText:", :"lowercaseSelectedText:", :"titlecaseSelectedText:", 
         :"stripTagsFromSelectedText:"
      selectedRange.length > 0
    when :"reformatText:", :"insertCloseTag:"
      @item.parseable?
    else
      true
    end
  end
  
  def visible?
    view && view.enclosingScrollView.superview && !view.hidden?
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
  
  def storeSelectedRange(item)
    if item && item.textual?
      @selectedRangeHash[item] = selectedRange
    end
  end

  def restoreSelectedRange(item)
    if item && item.textual?
      range = @selectedRangeHash[item] || NSMakeRange(0, 0)
      view.setSelectedRange(range)
    end
  end

end
