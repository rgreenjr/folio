class LineNumberRuler < NSRulerView

  DEFAULT_THICKNESS	= 22.0
  RULER_MARGIN		  = 5.0

  attr_accessor :font, :textColor

  def initWithScrollView(scrollView)
    initWithScrollView(scrollView, orientation:NSVerticalRuler)
    setClientView(scrollView.documentView)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'textDidChange:', name:NSTextStorageDidProcessEditingNotification, object:clientView.textStorage)
    @font = NSFont.labelFontOfSize(11.0)
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
    
    while line < count

      index = @lineIndices[line]

      if NSLocationInRange(index, range)
        rectCount = Pointer.new(:ulong_long)
        rects = layoutManager.rectArrayForCharacterRange(NSMakeRange(index, 0), withinSelectedCharacterRange:nullRange, inTextContainer:container, rectCount:rectCount)

        if rectCount[0] > 0
          # Note that the ruler view is only as tall as the visible portion. Need to compensate for the clipview's coordinates.
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

      if index > NSMaxRange(range)
        break
      end
      
      line += 1      
    end

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

    # lineEndIndex = Pointer.new(:ulong_long)
    # contentsEndIndex = Pointer.new(:ulong_long)
    # 
    # # check if text ends with a new line
    # text.getLineStart(nil, end:lineEndIndex[0], contentsEnd:contentsEndIndex[0], forRange:NSMakeRange(@lineIndices.last, 0))
    # 
    # if contentsEndIndex[0] < lineEndIndex[0]
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
    [DEFAULT_THICKNESS, 2 * RULER_MARGIN + stringSize.width].max
  end

  def requiredThickness	
  digits = Math.log10(@lineIndices.size + 1)
  sampleString = "8" * (digits + 2)
  stringSize = sampleString.sizeWithAttributes(@textAttributes)
  [DEFAULT_THICKNESS, 2 * RULER_MARGIN + stringSize.width].max.ceil
  end
   	
end