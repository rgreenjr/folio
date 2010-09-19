class TextViewController

  # Anything we colorize gets this attribute
  FOLIO_SYNTAX_COLORING_MODE_ATTR = "FolioTextDocumentSyntaxColoringMode"

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

    # NSNotificationCenter.defaultCenter.addObserver(self, selector:('processEditing:'), name:NSTextStorageDidProcessEditingNotification, object:nil)

    # # Put selection at top like Project Builder has it, so user sees it:
    # @textView.setSelectedRange(NSMakeRange(0, 0))
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

  def textDidChange(notification)
    return unless @item
    @item.content = @textView.textStorage.string
    @webView.reload(self)
  end


  # # Syntax Highlighting methods below
  # 
  # def processEditing(notification)
  #   # puts "processEditing"
  # 
  #   textStorage = @textView.textStorage
  #   range = textStorage.editedRange
  #   changeInLen = textStorage.changeInLength
  # 
  #   wasInUndoRedo = false
  #   # wasInUndoRedo = undoManager.isUndoing || undoManager.isRedoing
  # 
  #   textLengthMayHaveChanged = false
  # 
  #   # Was delete op or undo that could have changed text length?
  #   if wasInUndoRedo
  #     textLengthMayHaveChanged = true
  #     range = @textView.selectedRange
  #   end
  # 
  #   if changeInLen <= 0
  #     textLengthMayHaveChanged = true
  #   end
  # 
  #   #  Try to get chars around this to recolor any identifier we're in:
  #   if textLengthMayHaveChanged
  #     if range.location > 0
  #       range.location -= 1 
  #     end
  # 
  #     if (range.location + range.length + 2) < textStorage.length
  #       range.length += 2
  #     elsif (range.location + range.length + 1) < textStorage.length
  #       range.length += 1
  #     end
  #   end
  # 
  #   currRange = range
  # 
  #   # Perform the syntax coloring:
  #   if range.length > 0
  #     effectiveRange = Pointer.new(NSRange.type)
  # 
  #     rangeMode = textStorage.attribute(FOLIO_SYNTAX_COLORING_MODE_ATTR, atIndex:currRange.location, effectiveRange:effectiveRange)
  # 
  #     x = range.location
  # 
  #     # TODO: If we're in a multi-line comment and we're typing a comment-end
  #     # character, or we're in a string and we're typing a quote character,
  #     # this should include the rest of the text up to the next comment/string
  #     # end character in the recalc.
  # 
  #     # Scan up to prev line break:
  #     while x > 0
  #       char = textStorage.string[x]
  #       if char == "\n" || char == "\r"
  #         break
  #       end
  #       x -= 1
  #     end
  # 
  #     currRange.location = x
  # 
  #     # Scan up to next line break:
  #     x = range.location + range.length
  # 
  #     while x < textStorage.length
  #       char = textStorage.string[x]
  #       if char == "\n" || char == "\r"
  #         break
  #       end
  #       x += 1
  #     end
  # 
  #     currRange.length = x - currRange.location
  # 
  #     # Open identifier, comment etc.? Make sure we include the whole range.
  #     if rangeMode
  #       currRange = NSUnionRange(currRange, effectiveRange[0])
  #     end
  # 
  #     # Actually recolor the changed part:
  #     recolorRange(currRange)
  #   end
  # end
  # 
  # def textView(aTextView, shouldChangeTextInRange:affectedCharRange, replacementString:replacementString)
  #   # puts "textView(aTextView, shouldChangeTextInRange:affectedCharRange, replacementString:replacementString)"
  #   @affectedCharRange = affectedCharRange
  #   @replacementString = nil if @replacementString
  #   @replacementString = replacementString
  #   self.performSelector(:updateHighlights, withObject:nil, afterDelay:0.0)
  #   true
  # end
  # 
  # def updateHighlights
  #   return unless @replacementString == "\n" || @replacementString == "\r"
  # 
  #   hadSpaces = false
  #   prevLineBreak = 0
  #   str = textView.textStorage.string
  #   lastSpace = @affectedCharRange.location
  #   spacesRange = NSRange.new(0, 0)
  # 
  #   index = (@affectedCharRange.location == 0) ? 0 : @affectedCharRange.location - 1
  # 
  #   while true
  #     if index > (str.length - 1)
  #       break
  #     end
  #     case str[index]
  #     when "\n", "\r"
  #       prevLineBreak = index + 1
  #       index = 0  # terminate
  #       break
  #     when " ", "\t"
  #       unless hadSpaces
  #         lastSpace = index
  #         hadSpaces = true
  #       end
  #     else
  #       hadSpaces = false
  #       break
  #     end
  #     if index == 0
  #       break
  #     end
  #     index -= 1
  #   end
  # 
  #   if hadSpaces
  #     spacesRange.location = prevLineBreak
  #     spacesRange.length = lastSpace - prevLineBreak + 1
  #     if spacesRange.length > 0
  #       textView.insertText(str, substringWithRange:spacesRange)
  #     end
  #   end
  # end
  # 
  # 
  # # Try to apply syntax coloring to the text in our text view. This
  # # overwrites any styles the text may have had before. This function
  # # guarantees that it'll preserve the selection.
  # # 
  # # Note that the order in which the different things are colorized is
  # # important. E.g. identifiers go first, followed by comments, since that
  # # way colors are removed from identifiers inside a comment and replaced
  # # with the comment color, etc. 
  # # 
  # # The range passed in here is special, and may not include partial
  # # identifiers or the end of a comment. Make sure you include the entire
  # # multi-line comment etc. or it'll lose color.
  # # 
  # # This calls oldRecolorRange to handle old-style syntax definitions.
  # def recolorRange(range)
  #   return if @syntaxColoringBusy || @textView.nil? || range.length == 0
  # 
  #   # Kludge fix for case where we sometimes exceed text length
  #   diff = @textView.textStorage.length - (range.location + range.length)
  # 
  #   if diff < 0
  #     range.length += diff
  #   end
  # 
  #   begin
  # 
  #     @syntaxColoringBusy = true
  # 
  #     # Get the text we'll be working with:
  #     vString = NSMutableAttributedString.alloc.initWithString(@textView.textStorage.string.substringWithRange(range))
  # 
  #     # Load our dictionary which contains info on coloring this language:
  #     vSyntaxDefinition = syntaxDefinitionDictionary
  #           
  #     vComponentsEnny = vSyntaxDefinition["Components"].objectEnumerator
  # 
  #     # Loop over all available components:
  #     vCurrComponent = nil
  #     vStyles = defaultTextAttributes
  # 
  #     while vCurrComponent = vComponentsEnny.nextObject
  #       vComponentType = vCurrComponent["Type"]
  #       vComponentName = vCurrComponent["Name"]
  #       vColorKeyName = "SyntaxColoring:Color:".stringByAppendingString(vComponentName)
  # 
  #       vColor = colorValue(vCurrComponent["Color"])
  # 
  #       if vComponentType.isEqualToString("BlockComment")
  # 
  #         colorCommentsFrom(vCurrComponent["Start"], to:vCurrComponent["End"], 
  #         inString:vString, withColor:vColor, andMode:vComponentName)
  # 
  #       elsif vComponentType.isEqualToString("OneLineComment")
  # 
  #         colorOneLineComment(vCurrComponent["Start"], 
  #         inString:vString, withColor:vColor, andMode:vComponentName)
  # 
  #       elsif vComponentType.isEqualToString("String")
  # 
  #         colorStringsFrom(vCurrComponent["Start"], to:vCurrComponent["End"], 
  #         inString:vString, withColor:vColor, andMode:vComponentName, andEscapeChar:vCurrComponent["EscapeChar"])
  # 
  #       elsif vComponentType.isEqualToString("Tag")
  # 
  #         colorTagFrom(vCurrComponent["Start"], to:vCurrComponent["End"], 
  #         inString:vString, withColor:vColor, andMode:vComponentName, exceptIfMode:vCurrComponent["IgnoredComponent"])
  # 
  #       elsif vComponentType.isEqualToString("Keywords")
  # 
  #         vIdents = vCurrComponent["Keywords"]
  # 
  #         unless vIdents
  #           vIdents = NSUserDefaults.standardUserDefaults["SyntaxColoring:Keywords:" + vComponentName]
  #         end
  # 
  #         if !vIdents && vComponentName.isEqualToString("UserIdentifiers")
  #           vIdents = NSUserDefaults.standardUserDefaults[TD_USER_DEFINED_IDENTIFIERS]
  #         end
  # 
  #         if vIdents
  #           vIdentCharset = nil
  #           vCurrIdent = nil
  #           vCsStr = vCurrComponent["Charset"]
  # 
  #           if vCsStr
  #             vIdentCharset = NSCharacterSet.characterSetWithCharactersInString(vCsStr)
  #           end
  # 
  #           vItty = vIdents.objectEnumerator
  #           while vCurrIdent = vItty.nextObject
  #             colorIdentifier(vCurrIdent, inString:vString, withColor:vColor, andMode:vComponentName, charset:vIdentCharset)
  #           end
  #         end
  #       end
  #     end
  # 
  #     # Replace the range with our recolored part:
  #     vString.addAttributes(vStyles, range:NSMakeRange(0, vString.length))
  # 
  #     @textView.textStorage.replaceCharactersInRange(range, withAttributedString:vString)
  # 
  #     @syntaxColoringBusy = false
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: recolorRange => #{e.message}"
  #     @syntaxColoringBusy = false
  #     raise e
  #   end
  # end
  # 
  # # Delegate method called when our selection changes. Updates our status
  # # display to indicate which characters are selected.
  # def textView(aTextView, willChangeSelectionFromCharacterRange:oldSelectedCharRange, toCharacterRange:newSelectedCharRange)
  #   # puts "textView(aTextView, willChangeSelectionFromCharacterRange:oldSelectedCharRange, toCharacterRange:newSelectedCharRange)"
  # 
  #   startCh = newSelectedCharRange.location + 1
  #   endCh = newSelectedCharRange.location + newSelectedCharRange.length
  #   lineNo = 1
  #   lastLineStart = 0
  #   lastBreakChar = 0
  #   lastBreakOffs = 0
  # 
  #   # Calc line number:
  #   index = 0
  #   while (index < startCh && index < aTextView.string.length)
  #     char = aTextView.string[index]
  #     case char
  #     when "\n"
  #       # LF in CRLF sequence? Treat this as a single line break.
  #       if lastBreakOffs == (index - 1) && lastBreakChar == "\r"
  #         lastBreakOffs = 0
  #         lastBreakChar = 0
  #         next
  #       end
  #       lineNo += 1
  #       lastLineStart = index + 1
  #       lastBreakOffs = index
  #       lastBreakChar = char
  #     when "\r"
  #       lineNo += 1
  #       lastLineStart = index + 1
  #       lastBreakOffs = index
  #       lastBreakChar = char
  #     end
  #     index += 1
  #   end
  # 
  #   startChLine = (newSelectedCharRange.location - lastLineStart) + 1
  #   endChLine = (newSelectedCharRange.location - lastLineStart) + newSelectedCharRange.length
  # 
  #   newSelectedCharRange
  # end
  # 
  # # Apply syntax coloring to all strings. This is basically the same code
  # # as used for multi-line comments, except that it ignores the end
  # # character if it is preceded by a backslash.
  # def colorStringsFrom(startCh, to:endCh, inString:s, withColor:col, andMode:mode, andEscapeChar:vStringEscapeCharacter)
  #   # puts "colorStringsFrom"
  #   begin
  #     vScanner = NSScanner.scannerWithString(s.string)
  #     vStyles = {NSForegroundColorAttributeName => col, FOLIO_SYNTAX_COLORING_MODE_ATTR => mode}
  #     vIsEndChar = false
  #     vEscChar = "\\"
  # 
  #     if vStringEscapeCharacter
  #       if vStringEscapeCharacter.length != 0
  #         vEscChar = vStringEscapeCharacter[0]
  #       end
  #     end
  # 
  #     while !vScanner.isAtEnd
  #       vIsEndChar = false
  # 
  #       # Look for start of string:
  #       vScanner.scanUpToString(startCh, intoString:nil)
  #       vStartOffs = vScanner.scanLocation
  # 
  #       return unless vScanner.scanString(startCh, intoString:nil)
  # 
  #       # Loop until we find end-of-string marker or our text to color is finished:
  #       while !vIsEndChar && !vScanner.isAtEnd
  #         vScanner.scanUpToString(endCh, intoString: nil)
  # 
  #         # Backslash before the end marker? That means ignore the end marker.
  #         if vStringEscapeCharacter.length == 0 || s.string[vScanner.scanLocation - 1] != vEscChar
  #           # A real one! Terminate loop.
  #           vIsEndChar = true
  #         end
  # 
  #         # But skip this char before that.
  #         return unless vScanner.scanString(endCh, intoString:nil)
  #       end
  # 
  #       vEndOffs = vScanner.scanLocation
  # 
  #       # Now mess with the string's styles:
  #       s.setAttributes(vStyles, range:NSMakeRange(vStartOffs, vEndOffs - vStartOffs))
  #     end
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: colorStringsFrom => #{e.message}"
  #   end
  # end
  # 
  # # Colorize block-comments in the text view.
  # def colorCommentsFrom(startCh, to:endCh, inString:s, withColor:col, andMode:mode)
  #   # puts "colorCommentsFrom"
  #   begin
  #     vScanner = NSScanner.scannerWithString(s.string)
  #     vStyles = {NSForegroundColorAttributeName => col, FOLIO_SYNTAX_COLORING_MODE_ATTR => mode}
  # 
  #     while !vScanner.isAtEnd
  # 
  #       # Look for start of multi-line comment:
  #       vScanner.scanUpToString(startCh, intoString:nil)
  #       vStartOffs = vScanner.scanLocation
  # 
  #       return unless vScanner.scanString(startCh, intoString:nil)
  # 
  #       # Look for associated end-of-comment marker:
  #       vScanner.scanUpToString(endCh, intoString:nil)
  # 
  #       unless vScanner.scanString(endCh, intoString:nil)
  #         # Don't exit. If user forgot trailing marker, indicate this by "bleeding" until end of string.
  #       end
  # 
  #       vEndOffs = vScanner.scanLocation
  # 
  #       # Now mess with the string's styles:
  #       s.setAttributes(vStyles, range:NSMakeRange(vStartOffs, vEndOffs - vStartOffs))
  #     end
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: colorCommentsFrom => #{e.message}"
  #   end
  # end
  # 
  # # Colorize one-line-comments in the text view.
  # def colorOneLineComment(startCh, inString:s, withColor:col, andMode:mode)
  #   # puts "colorOneLineComment"
  #   begin
  #     vScanner = NSScanner.scannerWithString(s.string)
  #     vStyles = {NSForegroundColorAttributeName => col, FOLIO_SYNTAX_COLORING_MODE_ATTR => mode}
  # 
  #     while !vScanner.isAtEnd
  # 
  #       # Look for start of one-line comment:
  #       vScanner.scanUpToString(startCh, intoString:nil)
  # 
  #       vStartOffs = vScanner.scanLocation
  # 
  #       return unless vScanner.scanString(startCh, intoString:nil)
  # 
  #       # Look for associated line break:
  #       if !vScanner.skipUpToCharactersFromSet(NSCharacterSet.characterSetWithCharactersInString("\n\r"))
  #       end
  # 
  #       vEndOffs = vScanner.scanLocation
  # 
  #       # Now mess with the string's styles:
  #       s.setAttributes(vStyles, range:NSMakeRange(vStartOffs, vEndOffs - vStartOffs))
  #     end
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: colorOneLineComment"
  #   end
  # end
  # 
  # # Colorize keywords in the text view.
  # def colorIdentifier(ident, inString:s, withColor:col, andMode:mode, charset:cset)
  #   # puts "colorIdentifier"
  #   begin
  #     vScanner = NSScanner.scannerWithString(s.string)
  #     vStyles = {NSForegroundColorAttributeName => col, FOLIO_SYNTAX_COLORING_MODE_ATTR => mode}
  #     vStartOffs = 0
  # 
  #     # Skip any leading whitespace chars, somehow NSScanner doesn't do that:
  #     if cset
  #       while vStartOffs < s.string.length
  #         if cset.characterIsMember(s.string[vStartOffs])
  #           break 
  #         end
  #         vStartOffs += 1
  #       end
  #     end
  # 
  #     vScanner.setScanLocation(vStartOffs)
  # 
  #     while !vScanner.isAtEnd
  #       # Look for start of identifier:
  #       vScanner.scanUpToString(ident, intoString:nil)
  # 
  #       vStartOffs = vScanner.scanLocation
  # 
  #       unless vScanner.scanString(ident, intoString:nil)
  #         return
  #       end
  # 
  #       # Check that we're not in the middle of an identifier:
  #       if vStartOffs > 0
  #         # Alphanum character before identifier start?
  #         # If charset is NIL, this evaluates to NO.
  #         if cset && cset.characterIsMember(s.string[vStartOffs - 1])
  #           next
  #         end
  #       end
  # 
  #       if vStartOffs + ident.length + 1 < s.length
  #         # Alphanum character following our identifier?
  #         # If charset is NIL, this evaluates to NO.
  #         if cset && cset.characterIsMember(s.string[vStartOffs + ident.length])
  #           next
  #         end
  #       end
  # 
  #       # Now mess with the string's styles:
  #       s.setAttributes(vStyles, range:NSMakeRange(vStartOffs, ident.length))
  #     end
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: colorIdentifier => #{e.message}"
  #   end
  # end
  # 
  # # # Colorize HTML tags or similar constructs in the text view.
  # def colorTagFrom(startCh, to:endCh, inString:s, withColor:col, andMode:mode, exceptIfMode:ignoreAttr)
  #   # puts "colorTagFrom"
  #   begin
  #     vScanner = NSScanner.scannerWithString(s.string)
  #     vStyles = {NSForegroundColorAttributeName => col, FOLIO_SYNTAX_COLORING_MODE_ATTR => mode}
  # 
  #     while !vScanner.isAtEnd
  # 
  #       # Look for start of one-line comment:
  #       vScanner.scanUpToString(startCh, intoString:nil)
  #       vStartOffs = vScanner.scanLocation
  # 
  #       return if vStartOffs >= s.length
  # 
  #       scMode = s.attributesAtIndex(vStartOffs, effectiveRange:nil)[FOLIO_SYNTAX_COLORING_MODE_ATTR]
  # 
  #       return unless vScanner.scanString(startCh, intoString:nil)
  # 
  #       # If start lies in range of ignored style, don't colorize it:
  #       next if ignoreAttr && scMode && scMode.isEqualToString(ignoreAttr)
  # 
  #       # Look for matching end marker:
  #       while !vScanner.isAtEnd
  #         # Scan up to the next occurence of the terminating sequence:
  #         vScanner.scanUpToString(endCh, intoString:nil)
  # 
  #         # Now, if the mode of the end marker is not the mode we were told to ignore,
  #         # we're finished now and we can exit the inner loop:
  #         vEndOffs = vScanner.scanLocation
  #         if vEndOffs < s.length
  #           scMode = s.attributesAtIndex(vEndOffs, effectiveRange:nil)[FOLIO_SYNTAX_COLORING_MODE_ATTR]
  # 
  #           # Also skip the terminating sequence.
  #           vScanner.scanString(endCh, intoString:nil)
  # 
  #           if ignoreAttr.nil? || scMode.nil? || !scMode.isEqualToString(ignoreAttr)
  #             break
  #           end
  #         end
  # 
  #         # Otherwise we keep going, look for the next occurence of endCh and hope it isn't in that style.
  #       end
  # 
  #       vEndOffs = vScanner.scanLocation
  # 
  #       # Now mess with the string's styles:
  #       s.setAttributes(vStyles, range:NSMakeRange(vStartOffs, vEndOffs - vStartOffs))
  #     end
  # 
  #   rescue Exception => e
  #     puts "EXCEPTION: colorTagFrom => #{e.message}"
  #   end
  # end
  # 
  # def defaultTextAttributes
  #   @defaultTextAttributes ||= {NSFontAttributeName => NSFont.userFixedPitchFontOfSize(11.0)}
  # end 
  # 
  # def syntaxDefinitionDictionary
  #   @htmlDictionary ||= {
  #     "Components" => [{"EscapeChar"=>"", "Color"=>[1, 1, 1], "Start"=>"\"", "Type"=>"String", "End"=>"\"", "Name"=>"Strings"}, 
  #                      {"IgnoredComponent"=>"Strings", "Color"=>[0, 0, 0.5], "Start"=>"<", "Type"=>"Tag", "End"=>">", "Name"=>"Tags"}, 
  #                      {"EscapeChar"=>"", "Color"=>[0.86, 0, 0], "Start"=>"\"", "Type"=>"String", "End"=>"\"", "Name"=>"Strings"}, 
  #                      {"Color"=>[0.2, 0.5, 0.2], "Type"=>"Keywords", "Name"=>"Identifiers", "Keywords"=>["&lt;", "&gt;", "&amp;", "&auml;", "&uuml;", "&ouml;"]}, 
  #                      {"Color"=>[0.5078125, 0.16015625, 0.59765625], "Start"=>"<!--", "Type"=>"BlockComment", "End"=>"-->", "Name"=>"Comments"}], 
  #     "FileNameSuffixes"=>["htm", "html"]
  #   }
  # end
  # 
  # def colorValue(array)
  #   NSColor.colorWithCalibratedRed(array[0].to_f, green:array[1].to_f, blue:array[2].to_f, alpha:1.0)
  # end

end
