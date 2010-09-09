class LineNumberRuler < NSRulerView

  DEFAULT_THICKNESS	= 32.0
  RULER_MARGIN		  = 5.0

  attr_accessor :font, :textColor

  def initWithScrollView(scrollView)
    initWithScrollView(scrollView, orientation:NSVerticalRuler)
    setClientView(scrollView.documentView)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'textDidChange:', name:NSTextStorageDidProcessEditingNotification, object:clientView.textStorage)
    @font = NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize))
    @textColor = NSColor.colorWithCalibratedWhite(0.42, alpha:1.0)
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
    layoutManager = clientView.layoutManager
    container = clientView.textContainer
    text = clientView.string
    nullRange = NSMakeRange(NSNotFound, 0)

    yinset = clientView.textContainerInset.height
    visibleRect = scrollView.contentView.bounds

    # Find the characters that are currently visible
    glyphRange = layoutManager.glyphRangeForBoundingRect(visibleRect, inTextContainer:container)
    range = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange:nil)

    # Fudge the range a tad in case there is an extra new line at end.
    # It doesn't show up in the glyphs so would not be accounted for.
    range.length += 1

    count = @lineIndices.count
    index = 0

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

      break if (index > NSMaxRange(range))

      line += 1
    end
  end

  private

  def lineNumberForLocation(location)
    visibleRect = scrollView.contentView.bounds
    location += NSMinY(visibleRect)
    nullRange = NSMakeRange(NSNotFound, 0)
    layoutManager = clientView.layoutManager
    container = clientView.textContainer
    @lineIndices.each_with_index do |line, index|
      rectCount = Pointer.new(:ulong_long)
      rects = layoutManager.rectArrayForCharacterRange(NSMakeRange(line, 0), withinSelectedCharacterRange:nullRange, inTextContainer:container, rectCount:rectCount)
      rects.each do |rect|
        if location >= NSMinY(rect) && location < NSMaxY(rect)
          return (index + 1)
        end
      end
    end
    NSNotFound
  end

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
    text = clientView.string
    stringLength = text.length
    @lineIndices = []

    index = 0
    numberOfLines = 0

    loop do
      @lineIndices << index
      index = NSMaxRange(text.lineRangeForRange(NSMakeRange(index, 0)))
      numberOfLines += 1
      break if index >= stringLength
    end

    lineEnd = Pointer.new(:ulong_long)
    contentEnd = Pointer.new(:ulong_long)

    # check if text ends with a new line
    text.getLineStart(nil, end:lineEnd, contentsEnd:contentEnd, forRange:NSMakeRange(@lineIndices.last, 0))

    @lineIndices << index if contentEnd[0] < lineEnd[0]

    oldThickness = ruleThickness    
    newThickness = requiredThickness

    if (oldThickness - newThickness).abs > 1
      self.performSelector('updateRulerThinkness:', withObject:newThickness, afterDelay:0.0)      
    end
  end

  def requiredThickness
    digits = Math.log10(@lineIndices.size + 1)
    sampleString = "8" * (digits + 2)
    stringSize = sampleString.sizeWithAttributes(@textAttributes)
    [DEFAULT_THICKNESS, 2 * RULER_MARGIN + stringSize.width].max.ceil
  end

end