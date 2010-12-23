class LineNumberRuler < NSRulerView

  DEFAULT_THICKNESS	= 22.0
  RULER_MARGIN		  = 5.0

  attr_accessor :font, :textColor

  def initWithScrollView(scrollView)
    initWithScrollView(scrollView, orientation:NSVerticalRuler)
    setClientView(scrollView.documentView)
    ctr = NSNotificationCenter.defaultCenter
    ctr.addObserver(self, selector:'textDidChange:', name:NSTextStorageDidProcessEditingNotification, object:clientView.textStorage)
    @font = NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize))
    @textColor = NSColor.grayColor
    updateLineIndices
    updateTextAttributes
    self
  end

  def font=(font)
    @font = font
    updateTextAttributes
  end

  def textColor=(textColor)
    @textColor = textColor
    updateTextAttributes
  end

  def textDidChange(notification)
    updateLineIndices
    setNeedsDisplay(true)
  end

  def drawHashMarksAndLabelsInRect(aRect)
    text = clientView.string
    container = clientView.textContainer
    layoutManager = clientView.layoutManager

    yinset = clientView.textContainerInset.height
    visibleRect = scrollView.contentView.bounds

    nullRange = NSMakeRange(NSNotFound, 0)

    # Find the characters that are currently visible
    glyphRange = layoutManager.glyphRangeForBoundingRect(visibleRect, inTextContainer:container)
    range = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange:nil)

    # Fudge the range a tad in case there is an extra new line at end.
    # It doesn't show up in the glyphs so would not be accounted for.
    range.length += 1

    index = 0
    count = @lineIndices.size
    line = lineNumberForCharacterIndex(range.location, inText:text)

    # puts "count = #{count}"
    # puts "line = #{line}"

    while line < count

      index = @lineIndices[line]

      if NSLocationInRange(index, range)
        rectCount = Pointer.new(:ulong_long)
        rects = layoutManager.rectArrayForCharacterRange(NSMakeRange(index, 0),
          withinSelectedCharacterRange:nullRange, inTextContainer:container, rectCount:rectCount)

        if rectCount[0] > 0
          # Note that the ruler view is only as tall as the visible portion.
          # Need to compensate for the clipview's coordinates.
          ypos = yinset + NSMinY(rects[0]) - NSMinY(visibleRect)

          # Line numbers are internally stored starting at 0
          labelText = (line + 1).to_s
          stringSize = labelText.sizeWithAttributes(@textAttributes)

          # Draw string flush right, centered vertically within the line
          textRect = NSMakeRect(
            NSWidth(bounds) - stringSize.width - RULER_MARGIN,
            ypos + (NSHeight(rects[0]) - stringSize.height) / 2.0,
            NSWidth(bounds) - RULER_MARGIN * 2.0,
            NSHeight(rects[0])
          )

          labelText.drawInRect(textRect, withAttributes:@textAttributes)
        end
      end

      break if index > NSMaxRange(range)

      line += 1
    end
    
  end

  def physicalLineAtInsertion
    lineNumberForCharacterIndex(clientView.selectedRange.location, inText:clientView.string) + 1
  end

  def indexOfPhysicalLine(lineNumber)
    return 0 if lineNumber == 1
    index = lineCount = 0
    string = clientView.string
    length = string.length
    while index < length
      index = NSMaxRange(string.lineRangeForRange(NSMakeRange(index, 0)))
      break if lineCount == lineNumber - 2
      lineCount += 1
    end
    index
  end
  
  def logicalLineIndexAtPhysicalCharacterIndex(physicalIndex)
    index = lineCount = 0
    layoutManager = clientView.layoutManager
    numberOfGlyphs = NSMaxRange(layoutManager.glyphRangeForCharacterRange(NSMakeRange(0, physicalIndex), actualCharacterRange:nil))
    while index < numberOfGlyphs
      lineRange = Pointer.new(NSRange.type)
      layoutManager.lineFragmentRectForGlyphAtIndex(index, effectiveRange:lineRange)
      index = NSMaxRange(lineRange[0])
      lineCount += 1
    end
    index
  end

  def gotoLine(lineNumber)
    insertionLocation = logicalLineIndexAtPhysicalCharacterIndex(indexOfPhysicalLine(lineNumber))
    clientView.selectedRange = NSMakeRange(insertionLocation, 0)
    clientView.scrollRangeToVisible(NSMakeRange(insertionLocation, 0))
  end

  private

  def lineNumberForCharacterIndex(index, inText:text)
    left = 0
    right = @lineIndices.count
    while right - left > 1
      mid = (right + left) / 2
      lineStart = @lineIndices[mid]
      if index < lineStart
        right = mid
      elsif index > lineStart
        left = mid
      else
        return mid
      end
    end
    left
  end

  def updateRulerThinkness(newThickness)
    setRuleThickness(newThickness)
  end

  def updateTextAttributes
    @textAttributes = { NSFontAttributeName => @font, NSForegroundColorAttributeName => @textColor }
  end

  def updateLineIndices
    @lineIndices = []

    text = clientView.string
    stringLength = text.length

    index = 0

    loop do
      @lineIndices << index
      index = NSMaxRange(text.lineRangeForRange(NSMakeRange(index, 0)))
      break if index >= stringLength
    end

    # lineEnd = Pointer.new(:ulong_long)
    # contentsEnd = Pointer.new(:ulong_long)
    #
    # # check if text ends with a new line
    # text.getLineStart(nil, end:lineEnd, contentsEnd:contentsEnd, forRange:NSMakeRange(@lineIndices.last, 0))
    #
    # if contentsEnd[0] < lineEnd[0]
    #   @lineIndices << index
    # end

    oldThickness = ruleThickness
    newThickness = requiredThickness

    if (oldThickness - newThickness).abs > 1
      self.performSelector('updateRulerThinkness:', withObject:newThickness, afterDelay:0.0)
    end
  end

  def requiredThickness
    digits = Math.log10(@lineIndices.size + 1).ceil
    stringSize = ("8" * digits).sizeWithAttributes(@textAttributes)
    [DEFAULT_THICKNESS, (2 * RULER_MARGIN + stringSize.width).ceil].max
  end

end