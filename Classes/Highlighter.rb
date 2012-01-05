class Highlighter

  FOLIO_ATTR = "FolioTextDocumentSyntaxColoringMode"
  
  attr_accessor :textView
  
  def initialize(textView)
    @textView = textView
    
    # register for text changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"processEditing:", name:NSTextStorageDidProcessEditingNotification, object:@textView.textStorage)
      
    # get user preferences  
    processUserPreferences(PreferencesController.sharedPreferencesController)    
  end

  def mediaType=(type)
    @syntaxDictionary = syntaxDictionaryForMediaType(type)
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

    currRange = range

    # Perform the syntax coloring:
    if range.length > 0
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

  def textView(aTextView, shouldChangeTextInRange:affectedCharRange, replacementString:replacementString)
    @affectedCharRange = affectedCharRange
    @replacementString = replacementString
    self.performSelector(:updateHighlights, withObject:nil, afterDelay:0.0)
    true
  end

  def updateHighlights
    return unless @replacementString == "\n" || @replacementString == "\r"

    hadSpaces = false
    prevLineBreak = 0
    str = textView.textStorage.string
    lastSpace = @affectedCharRange.location
    spacesRange = NSRange.new(0, 0)

    index = (@affectedCharRange.location == 0) ? 0 : @affectedCharRange.location - 1

    while true
      if index > (str.length - 1)
        break
      end
      case str[index]
      when "\n", "\r"
        prevLineBreak = index + 1
        index = 0  # terminate
        break
      when " ", "\t"
        unless hadSpaces
          lastSpace = index
          hadSpaces = true
        end
      else
        hadSpaces = false
        break
      end
      if index == 0
        break
      end
      index -= 1
    end

    if hadSpaces
      spacesRange.location = prevLineBreak
      spacesRange.length = lastSpace - prevLineBreak + 1
      if spacesRange.length > 0
        textView.insertText(str, substringWithRange:spacesRange)
      end
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
    return if @syntaxColoringBusy || @textView.nil? || range.length == 0 || @syntaxDictionary.nil?

    # handle case where we may exceed text length
    diff = @textView.textStorage.length - (range.location + range.length)    
    
    range.length += diff if diff < 0

    begin
      @syntaxColoringBusy = true
            
      string = NSMutableAttributedString.alloc.initWithString(@textView.textStorage.string.substringWithRange(range))

      @syntaxDictionary.each do |component|
        
        type  = component[:type]
        name  = component[:name]
        color = component[:color]
        
        case type
        when :blockCommentType
          colorCommentsFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name)
        when :oneLineCommentType
          colorOneLineComment(component[:start], inString:string, withColor:color, andMode:name)
        when :stringType
          colorStringsFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name, andEscapeChar:component[:escapeChar])
        when :tagType
          colorTagFrom(component[:start], to:component[:end], inString:string, withColor:color, andMode:name, exceptIfMode:component[:ignored])
        when :keywordType
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
      string.addAttributes(@textAttributes, range:NSMakeRange(0, string.length))

      @textView.textStorage.replaceCharactersInRange(range, withAttributedString:string)

      @syntaxColoringBusy = false

    rescue Exception => e
      puts "EXCEPTION: recolorRange => #{e.message}"
      @syntaxColoringBusy = false
      raise e
    end
  end

  # Apply syntax coloring to all strings. This is basically the same code
  # as used for multi-line comments, except that it ignores the end
  # character if it is preceded by a backslash.
  def colorStringsFrom(startChar, to:endChar, inString:string, withColor:color, andMode:mode, andEscapeChar:escapeChar)
    begin
      scanner = NSScanner.scannerWithString(string.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode }
      
      foundEndChar = false

      if escapeChar && escapeChar.length != 0
        escChar = escapeChar[0]
      else
        escChar = "\\"
      end

      while !scanner.isAtEnd
        foundEndChar = false

        # Look for start of string:
        scanner.scanUpToString(startChar, intoString:nil)
        startOffset = scanner.scanLocation

        return unless scanner.scanString(startChar, intoString:nil)

        # Loop until we find end-of-string marker or our text to color is finished:
        while !foundEndChar && !scanner.isAtEnd
          scanner.scanUpToString(endChar, intoString: nil)

          # Backslash before the end marker? That means ignore the end marker.
          if escapeChar.length == 0 || string.string[scanner.scanLocation - 1] != escChar
            # A real one! Terminate loop.
            foundEndChar = true
          end

          # But skip this char before that.
          return unless scanner.scanString(endChar, intoString:nil)
        end

        endOffset = scanner.scanLocation

        # Now mess with the string's styles:
        string.setAttributes(styles, range:NSMakeRange(startOffset, endOffset - startOffset))
      end

    rescue Exception => e
      puts "EXCEPTION: colorStringsFrom => #{e.message}"
    end
  end

  # Colorize block-comments in the text view.
  def colorCommentsFrom(startChar, to:endChar, inString:string, withColor:color, andMode:mode)
    begin
      scanner = NSScanner.scannerWithString(string.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode }

      while !scanner.isAtEnd

        # Look for start of multi-line comment:
        scanner.scanUpToString(startChar, intoString:nil)
        startOffset = scanner.scanLocation

        return unless scanner.scanString(startChar, intoString:nil)

        # Look for associated end-of-comment marker:
        scanner.scanUpToString(endChar, intoString:nil)

        unless scanner.scanString(endChar, intoString:nil)
          # Don't exit. If user forgot trailing marker, indicate this by "bleeding" until end of string.
        end

        endOffset = scanner.scanLocation

        # Now mess with the string's styles:        
        string.setAttributes(styles, range:NSMakeRange(startOffset, endOffset - startOffset))
      end

    rescue Exception => e
      puts "EXCEPTION: colorCommentsFrom => #{e.message}"
    end
  end
  
  # Colorize one-line-comments in the text view.
  def colorOneLineComment(startChar, inString:string, withColor:color, andMode:mode)
    begin
      scanner = NSScanner.scannerWithString(string.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode }

      while !scanner.isAtEnd

        # Look for start of one-line comment:
        scanner.scanUpToString(startChar, intoString:nil)

        startOffset = scanner.scanLocation

        return unless scanner.scanString(startChar, intoString:nil)

        # Look for associated line break:
        if !scanner.skipUpToCharactersFromSet(NSCharacterSet.characterSetWithCharactersInString("\n\r"))
        end

        endOffset = scanner.scanLocation

        # Now mess with the string's styles:
        string.setAttributes(styles, range:NSMakeRange(startOffset, endOffset - startOffset))
      end

    rescue Exception => e
      puts "EXCEPTION: colorOneLineComment"
    end
  end

  # Colorize keywords in the text view.
  def colorIdentifier(ident, inString:string, withColor:color, andMode:mode, charset:cset)
    begin
      scanner = NSScanner.scannerWithString(string.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode }
      
      startOffset = 0

      # Skip any leading whitespace chars, somehow NSScanner doesn't do that:
      if cset
        while startOffset < string.string.length
          if cset.characterIsMember(string.string[startOffset])
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
          if cset && cset.characterIsMember(string.string[startOffset - 1])
            next
          end
        end

        if startOffset + ident.length + 1 < string.length
          # Alphanum character following our identifier?
          # If charset is NIL, this evaluates to NO.
          if cset && cset.characterIsMember(string.string[startOffset + ident.length])
            next
          end
        end

        # Now mess with the string's styles:
        string.setAttributes(styles, range:NSMakeRange(startOffset, ident.length))
      end

    rescue Exception => e
      puts "EXCEPTION: colorIdentifier => #{e.message}"
    end
  end

  # # Colorize HTML tags or similar constructs in the text view.
  def colorTagFrom(startChar, to:endChar, inString:string, withColor:color, andMode:mode, exceptIfMode:ignoreAttr)
    begin
      scanner = NSScanner.scannerWithString(string.string)
      
      styles = { NSForegroundColorAttributeName => color, FOLIO_ATTR => mode }

      while !scanner.isAtEnd

        # Look for start of one-line comment:
        scanner.scanUpToString(startChar, intoString:nil)
        startOffset = scanner.scanLocation

        return if startOffset >= string.length

        scMode = string.attributesAtIndex(startOffset, effectiveRange:nil)[FOLIO_ATTR]

        return unless scanner.scanString(startChar, intoString:nil)

        # If start lies in range of ignored style, don't colorize it:
        next if ignoreAttr && scMode && scMode.isEqualToString(ignoreAttr)

        # Look for matching end marker:
        while !scanner.isAtEnd
          # Scan up to the next occurence of the terminating sequence:
          scanner.scanUpToString(endChar, intoString:nil)

          # Now, if the mode of the end marker is not the mode we were told to ignore,
          # we're finished now and we can exit the inner loop:
          endOffset = scanner.scanLocation
          if endOffset < string.length
            scMode = string.attributesAtIndex(endOffset, effectiveRange:nil)[FOLIO_ATTR]

            # Also skip the terminating sequence.
            scanner.scanString(endChar, intoString:nil)

            if ignoreAttr.nil? || scMode.nil? || !scMode.isEqualToString(ignoreAttr)
              break
            end
          end

          # Otherwise we keep going, look for the next occurence of endChar and hope it isn't in that style.
        end

        endOffset = scanner.scanLocation

        # Now mess with the string's styles:
        string.setAttributes(styles, range:NSMakeRange(startOffset, endOffset - startOffset))
      end

    rescue Exception => e
      puts "EXCEPTION: colorTagFrom => #{e.message}"
    end
  end
  
  def processUserPreferences(preferenceController)
    @textAttributes = { NSFontAttributeName => preferenceController.font }
    @stringColor = preferenceController.stringColor
    @tagColor = preferenceController.tagColor
    @commentColor = preferenceController.commentColor
    @identifierColor = preferenceController.identifierColor
    @backgroundColor = preferenceController.backgroundColor
    clearSyntaxDictionaries
  end
    
  def syntaxDictionaryForMediaType(mediaType)
    case mediaType
    when Media::HTML
      xmlSyntaxDictionary
    when Media::XML
      xmlSyntaxDictionary
    when Media::CSS
      cssSyntaxDictionary
    else
      defaultSyntaxDictionary
    end
  end
  
  def xmlSyntaxDictionary
    @xmlSyntaxDictionary ||= [
      { 
        :name       => "Tags",
        :type       => :tagType, 
        :color      => @tagColor, 
        :start      => "<", 
        :end        => ">", 
        :ignored    => "Strings", 
      },
      { 
        :name       => "Strings",
        :type       => :stringType, 
        :color      => @stringColor, 
        :start      => "\"", 
        :end        => "\"", 
        :escapeChar => "",
      },
      { 
        :name       => "Identifiers", 
        :type       => :keywordType, 
        :color      => @identifierColor, 
        :keywords   => ["&lt;", "&gt;", "&amp;", "&auml;", "&uuml;", "&ouml;"],
      },
      { 
        :name       => "Comments",
        :type       => :blockCommentType, 
        :color      => @commentColor, 
        :start      => "<!--",
        :end        => "-->", 
      }
    ]
  end
  
  def cssSyntaxDictionary
    @cssSyntaxDictionary ||= [
      { 
        :name       => "Tags",
        :type       => :tagType, 
        :color      => @tagColor, 
        :start      => "{", 
        :end        => "} ", 
        :ignored    => "Strings", 
      },
      { 
        :name       => "Strings",
        :type       => :stringType, 
        :color      => @stringColor, 
        :start      => "\"", 
        :end        => "\"", 
        :escapeChar => "",
      },
      { 
        :name       => "Identifiers", 
        :type       => :keywordType, 
        :color      => @identifierColor, 
        :keywords   => ["background:", "background-attachment:", "background-color:", "background-image:", "background-position:", 
                        "background-repeat:", "border:", "border-bottom:", "border-bottom-color:", "border-bottom-style:", "border-bottom-width:", 
                        "border-color:", "border-left:", "border-left-color:", "border-left-style:", "border-left-width:", "border-right:", 
                        "border-right-color:", "border-right-style:", "border-right-width:", "border-style:", "border-top:", "border-top-color:", 
                        "border-top-style:", "border-top-width:", "border-width:", "clear:", "cursor:", "display:", "float:", "position:", 
                        "visibility:", "height:", "line-height:", "max-height:", "min-height:", "min-width:", "width:", "font:", "font-family:", 
                        "font-size:", "font-size-adjust:", "font-strech:", "font-style:", "font-variant:", "font-weight:", "content:", 
                        "counter-increment:", "counter-reset:", "quotes:", "list-style:", "list-style-image:", "list-style-position:", 
                        "list-style-type:", "marker-offset:", "margin:", "margin-bottom:", "margin-left:", "margin-right:", "margin-top:", 
                        "outline:", "outline-color:", "outline-style:", "outline-width:", "padding:", "padding-bottom:", "padding-left:", 
                        "padding-right:", "padding-top:", "bottom:", "clip:", "left:", "overflow:", "right:", "top:", "vertical-align:", 
                        "z-index:", "border-collapse:", "border-spacing:", "caption-side:", "empty-cells:", "table-layout:", "color:", 
                        "direction:", "letter-spacing:", "text-align:", "text-decoration:", "text-indent:", "text-shadow:", "text-transform:", 
                        "unicode-bidi:", "white-space:"],
      },
      { 
        :name       => "Comments",
        :type       => :blockCommentType, 
        :color      => @commentColor, 
        :start      => "/*",
        :end        => "*/", 
      }
    ]
  end
  
  def defaultSyntaxDictionary
    @defaultSyntaxDictionary ||= []
  end
  
  def clearSyntaxDictionaries
    @xmlSyntaxDictionary = nil
    @cssSyntaxDictionary = nil
    @defaultSyntaxDictionary = nil
  end

end