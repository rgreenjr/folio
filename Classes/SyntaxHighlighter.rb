class SyntaxHighlighter

  FOLIO_ATTR = "FolioSyntaxColoringMode"
  
  attr_accessor :textView
  
  def initialize(textView)
    @textView = textView
    
    # register for text changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"processEditing:", name:NSTextStorageDidProcessEditingNotification, object:@textView.textStorage)
      
    # get user preferences  
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
      rangeMode = textStorage.attribute(FOLIO_ATTR, atIndex:currRange.location, effectiveRange:effectiveRange)
      
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

  # Try to apply syntax coloring to the text in our text view. This
  # overwrites any styles the text may have had before. This function
  # guarantees that it'll preserve the selection.
  # 
  # Note that the order in which the different things are colorized is
  # important. E.g. identifiers go first, followed by comments, since that
  # way colors are removed from identifiers inside a comment and replaced
  # with the comment color, etc. 
  # 
  # The range passed in here is special, and may not include partial
  # identifiers or the end of a comment. Make sure you include the entire
  # multi-line comment etc. or it'll lose color.
  # 
  # This calls oldRecolorRange to handle old-style syntax definitions.
  def recolorRange(range)
    return if @syntaxColoringBusy || @textView.nil? || range.length == 0 || @syntax.nil?

    # handle case where we may exceed text length
    diff = @textView.textStorage.length - (range.location + range.length)    
    
    range.length += diff if diff < 0

    begin
      @syntaxColoringBusy = true
      string = NSMutableAttributedString.alloc.initWithString(@textView.textStorage.string.substringWithRange(range))
      string.addAttributes(@defaultTextAttributes, range:NSMakeRange(0, string.length))
      @syntax.each do |component|
        type  = component[:type]
        name  = component[:name]
        color = colorForSyntaxType(type)
        case type
        when Syntax::BLOCK_COMMENT_TYPE
          colorBlockCommentsFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name)
        when Syntax::COMMENT_TYPE
          colorOneLineComment(component[:start], inString:string, withColor:color, andMode:name)
        when Syntax::STRING_TYPE
          colorStringsFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name, andEscapeChar:component[:escapeChar])
        when Syntax::TAG_TYPE
          colorTagFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name, exceptIfMode:component[:ignored])
        when Syntax::KEYWORD_TYPE
          keywords = component[:keywords]
          if keywords
            keywordCharacterSet = component[:charset] ? NSCharacterSet.characterSetWithCharactersInString(component[:charset]) : nil
            keywords.each do |keyword|
              colorIdentifier(keyword, inString:string, withColor:color, andMode:name, charset:keywordCharacterSet)
            end
          end
        end
      end
      # Replace the range with our recolored part:
      @textView.textStorage.replaceCharactersInRange(range, withAttributedString:string)
      @syntaxColoringBusy = false
    rescue Exception => e
      puts "EXCEPTION: recolorRange => #{e.message}"
      @syntaxColoringBusy = false
      raise e
    end
  end

  # TODO - Add escapeChar support
  def colorStringsFrom(startStr, to:endStr, inString:attributedString, withColor:color, andMode:mode, andEscapeChar:escapeChar)
    begin
      string = attributedString.string
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode, NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      index = 0
      while index < string.length
        range = findStringRange(string, index, startStr, endStr, mode)
        return unless range
        attributedString.setAttributes(styles, range:range)
        index = range.location + range.length
      end
    rescue Exception => e
      puts "EXCEPTION: colorStringsFrom => #{e.message}"
    end
  end
  
  def colorBlockCommentsFrom(startStr, to:endStr, inString:attributedString, withColor:color, andMode:mode)
    begin
      string = attributedString.string
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode, NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      index = 0
      while index < string.length
        range = findStringRange(string, index, startStr, endStr, mode)
        return unless range
        attributedString.setAttributes(styles, range:range)
        index = range.location + range.length
      end
    rescue Exception => e
      puts "EXCEPTION: colorBlockCommentsFrom => #{e.message}"
    end
  end
  
  def colorOneLineComment(startStr, inString:attributedString, withColor:color, andMode:mode)
    begin
      string = attributedString.string
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode, NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      index = 0
      while index < string.length
        startOffset = string.index(startStr, index)
        return nil unless startOffset
        index = startOffset + startStr.length

        # scan to end of line
        while index < string.length && string[index] != "\n" && string[index] != "\r"
          index += 1
        end

        range = NSMakeRange(startOffset, index - startOffset)
        puts "(#{range.location}, #{range.length}) => #{mode}"

        attributedString.setAttributes(styles, range:range)
        index = range.location + range.length
      end
    rescue Exception => e
      puts "EXCEPTION: colorOneLineComment"
    end
  end

  # Colorize keywords in the text view.
  def colorIdentifier(ident, inString:attributedString, withColor:color, andMode:mode, charset:cset)
    begin
      scanner = NSScanner.scannerWithString(attributedString.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode, NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }
      
      startOffset = 0

      # Skip any leading whitespace chars, somehow NSScanner doesn't do that:
      if cset
        while startOffset < attributedString.string.length
          if cset.characterIsMember(attributedString.string[startOffset])
            break 
          end
          startOffset += 1
        end
      end

      scanner.setScanLocation(startOffset)

      while !scanner.isAtEnd
        # Look for start of identifier:
        scanner.scanUpToString(ident, intoString:nil)

        startOffset = scanner.scanLocation

        unless scanner.scanString(ident, intoString:nil)
          return
        end

        # Check that we're not in the middle of an identifier:
        if startOffset > 0
          # Alphanum character before identifier start?
          # If charset is NIL, this evaluates to NO.
          if cset && cset.characterIsMember(attributedString.string[startOffset - 1])
            next
          end
        end

        if startOffset + ident.length + 1 < attributedString.length
          # Alphanum character following our identifier?
          # If charset is NIL, this evaluates to NO.
          if cset && cset.characterIsMember(attributedString.string[startOffset + ident.length])
            next
          end
        end

        # Now mess with the string's styles:
        attributedString.setAttributes(styles, range:NSMakeRange(startOffset, ident.length))
      end

    rescue Exception => e
      puts "EXCEPTION: colorIdentifier => #{e.message}"
    end
  end

  # Colorize HTML tags or similar constructs in the text view.
  def colorTagFrom(startStr, to:endStr, inString:attributedString, withColor:color, andMode:mode, exceptIfMode:ignoreAttr)
    begin
      scanner = NSScanner.scannerWithString(attributedString.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode, NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0) }

      while !scanner.isAtEnd

        # Look for start of one-line comment:
        scanner.scanUpToString(startStr, intoString:nil)
        startOffset = scanner.scanLocation

        return if startOffset >= attributedString.length

        scMode = attributedString.attributesAtIndex(startOffset, effectiveRange:nil)[FOLIO_ATTR]

        return unless scanner.scanString(startStr, intoString:nil)

        # If start lies in range of ignored style, don't colorize it:
        next if ignoreAttr && scMode && scMode.isEqualToString(ignoreAttr)

        # Look for matching end marker:
        while !scanner.isAtEnd
          # Scan up to the next occurence of the terminating sequence:
          scanner.scanUpToString(endStr, intoString:nil)

          # Now, if the mode of the end marker is not the mode we were told to ignore,
          # we're finished now and we can exit the inner loop:
          endOffset = scanner.scanLocation
          if endOffset < attributedString.length
            scMode = attributedString.attributesAtIndex(endOffset, effectiveRange:nil)[FOLIO_ATTR]

            # Also skip the terminating sequence.
            scanner.scanString(endStr, intoString:nil)

            if ignoreAttr.nil? || scMode.nil? || !scMode.isEqualToString(ignoreAttr)
              break
            end
          end

          # Otherwise we keep going, look for the next occurence of endStr and hope it isn't in that style.
        end

        endOffset = scanner.scanLocation

        # Now mess with the string's styles:
        attributedString.setAttributes(styles, range:NSMakeRange(startOffset, endOffset - startOffset))
      end

    rescue Exception => e
      puts "EXCEPTION: colorTagFrom => #{e.message}"
    end
  end
  
  def processUserPreferences(preferenceController)
    @stringColor = preferenceController.stringColor
    @tagColor = preferenceController.tagColor
    @commentColor = preferenceController.commentColor
    @keywordColor = preferenceController.keywordColor
    @backgroundColor = preferenceController.backgroundColor
    @foregroundColor = preferenceController.foregroundColor
    @defaultTextAttributes = { NSFontAttributeName => preferenceController.font, NSForegroundColorAttributeName => @foregroundColor }
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
      Syntax.defaultInstance
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

  def findStringRange(string, index, startStr, endStr, mode)
    startOffset = string.index(startStr, index)
    return nil unless startOffset
    index = startOffset + startStr.length
    endOffset = string.index(endStr, index)
    endOffset = endOffset ? endOffset + endStr.length : string.length
    range = NSMakeRange(startOffset, endOffset - startOffset)
    # puts "(#{range.location}, #{range.length}) => #{mode}"
    range
  end

end