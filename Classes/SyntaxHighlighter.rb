class SyntaxHighlighter

  FOLIO_COLORING_MODE = "FolioColoringMode"
  
  attr_accessor :textView
  
  def initialize(textView)
    @textView = textView
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"processEditing:", name:NSTextStorageDidProcessEditingNotification, object:@textView.textStorage)
    processUserPreferences(PreferencesController.sharedPreferencesController)    
  end

  def mediaType=(type)
    @syntax = syntaxForMediaType(type)
  end

  def processEditing(notification)    
    textStorage = @textView.textStorage
    range = textStorage.editedRange
    changeInLen = textStorage.changeInLength

    wasInUndoRedo = false
    # wasInUndoRedo = undoManager.isUndoing || undoManager.isRedoing

    textLengthMayHaveChanged = false

    # Was delete op or undo that could have changed text length?
    if wasInUndoRedo
      textLengthMayHaveChanged = true
      range = @textView.selectedRange
    end

    if changeInLen <= 0
      textLengthMayHaveChanged = true
    end

    #  Try to get chars around this to recolor any identifier we're in:
    if textLengthMayHaveChanged
      if range.location > 0
        range.location -= 1 
      end

      if (range.location + range.length + 2) < textStorage.length
        range.length += 2
      elsif (range.location + range.length + 1) < textStorage.length
        range.length += 1
      end
    end

    # Perform the syntax coloring:
    if range.length > 0

      currRange = range
      effectiveRange = Pointer.new(NSRange.type)
      rangeMode = textStorage.attribute(FOLIO_COLORING_MODE, atIndex:currRange.location, effectiveRange:effectiveRange)
      
      x = range.location

      # TODO: If we're in a multi-line comment and we're typing a comment-end
      # character, or we're in a string and we're typing a quote character,
      # this should include the rest of the text up to the next comment/string
      # end character in the recalc.

      # Scan up to prev line break:
      while x > 0
        char = textStorage.string[x]
        if char == "\n" || char == "\r"
          break
        end
        x -= 1
      end

      currRange.location = x

      # Scan up to next line break:
      x = range.location + range.length

      while x < textStorage.length
        char = textStorage.string[x]
        if char == "\n" || char == "\r"
          break
        end
        x += 1
      end

      currRange.length = x - currRange.location

      # Open identifier, comment etc.? Make sure we include the whole range.
      if rangeMode
        currRange = NSUnionRange(currRange, effectiveRange[0])
      end

      # Actually recolor the changed part:
      recolorRange(currRange)
    end
  end

  def recolorRange(range)
    return if @highlightingActive || @textView.nil? || range.length == 0 || @syntax.nil?

    @highlightingActive = true

    # dont't exceed text length
    diff = @textView.textStorage.length - (range.location + range.length)
    range.length += diff if diff < 0

    # duplicate specified range of string
    string = NSMutableAttributedString.alloc.initWithString(@textView.textStorage.string.substringWithRange(range))

    # assign default font and color attributions
    string.addAttributes(@defaultTextAttributes, range:NSMakeRange(0, string.length))

    # highlighting order here is important

    # highlight keywords
    colorString(string, @syntax.keywords, @keywordColor) if @syntax.keywords

    # highlight tag
    colorString(string, @syntax.tags, @tagColor) if @syntax.tags

    # highlight strings
    colorString(string, @syntax.strings, @stringColor) if @syntax.strings

    # highlight comments
    colorString(string, @syntax.comments, @commentColor) if @syntax.comments

    # highlight blockComments
    colorString(string, @syntax.blockComments, @commentColor) if @syntax.blockComments

    # replace specified with colored text
    @textView.textStorage.replaceCharactersInRange(range, withAttributedString:string) 
         
  ensure
    @highlightingActive = false
  end
  
  def colorString(attributedString, syntaxComponent, color)
    textAttributes =  { NSFontAttributeName => @font, NSForegroundColorAttributeName => color, FOLIO_COLORING_MODE => syntaxComponent[:name] }
    string = attributedString.string
    string.scan(syntaxComponent[:regex]) do
      start, stop = Regexp.last_match.offset(0)
      attributedString.setAttributes(textAttributes, range:NSMakeRange(start, stop - start))
    end
  end
  
  def processUserPreferences(preferenceController)
    @stringColor = preferenceController.stringColor
    @tagColor = preferenceController.tagColor
    @commentColor = preferenceController.commentColor
    @keywordColor = preferenceController.keywordColor
    @foregroundColor = preferenceController.foregroundColor
    @backgroundColor = preferenceController.backgroundColor
    @font = preferenceController.font
    @defaultTextAttributes = { NSFontAttributeName => @font, NSForegroundColorAttributeName => @foregroundColor }
  end
    
  def syntaxForMediaType(mediaType)
    case mediaType
    when Media::HTML
      XMLSyntax.sharedInstance
    when Media::XML
      XMLSyntax.sharedInstance
    when Media::CSS
      CSSSyntax.sharedInstance
    else
      Syntax.sharedInstance
    end
  end
  
  def colorForSyntaxType(type)
    case type
    when Syntax::STRING_TYPE
      @stringColor
    when Syntax::TAG_TYPE
      @tagColor
    when Syntax::KEYWORD_TYPE
      @keywordColor
    when Syntax::BLOCK_COMMENT_TYPE
      @commentColor
    when Syntax::COMMENT_TYPE
      @commentColor
    else
      NSColor.blackColor
    end
  end

end