class LineNumberRuler < NSRulerView

  DEFAULT_THICKNESS	= 32.0
  RULER_MARGIN		  = 5.0

  attr_accessor :font, :textColor, :alternateTextColor, :backgroundColor

  def initWithScrollView(scrollView)
    initWithScrollView(scrollView, orientation:NSVerticalRuler)
    self.clientView = scrollView.documentView
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'textDidChange:', name:NSTextStorageDidProcessEditingNotification, object:clientView.textStorage)
    @font = NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize))
    @textColor = NSColor.colorWithCalibratedWhite(0.42, alpha:1.0)
    @alternateTextColor = NSColor.whiteColor
    updateTextAttributes
    self
  end

  def lineIndices
    calculateLines unless @lineIndices
    @lineIndices
  end

  def textDidChange(notification)
    @lineIndices = nil
    self.needsDisplay = true
  end

  def lineNumberForLocation(location)
    view = self.clientView
    visibleRect = self.scrollView.contentView.bounds
    location += NSMinY(visibleRect)
    nullRange = NSMakeRange(NSNotFound, 0)
    layoutManager = view.layoutManager
    container = view.textContainer
    self.lineIndices.each_with_index do |line, index|
      rectCount = Pointer.new(:ulong_long)
      rects = layoutManager.rectArrayForCharacterRange(NSMakeRange(line, 0), withinSelectedCharacterRange:nullRange, inTextContainer:container, rectCount:rectCount)
      rects.each do |rect|
        return (index + 1) if location >= NSMinY(rect) && location < NSMaxY(rect)
      end
    end
    NSNotFound
  end

  def calculateLines
    text = self.clientView.string
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

    oldThickness = self.ruleThickness    
    @newThickness = self.requiredThickness

    if (oldThickness - @newThickness).abs > 1
      self.performSelector(:updateRulerThinkness, withObject:nil, afterDelay:0.0)      
    end
  end

  def updateRulerThinkness
    self.ruleThickness = @newThickness
  end

  def lineNumberForCharacterIndex(index, inText:text)
    lines = self.lineIndices
    left = 0
    right = self.lineIndices.count
    while right - left > 1
      mid = (right + left) / 2
      lineStart = lines[mid]
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
  
  def font=(font)
    @font = font
    updateTextAttributes
  end

  def textColor=(textColor)
    @textColor = textColor
    updateTextAttributes
  end

  def updateTextAttributes
    @textAttributes = { NSFontAttributeName => @font, NSForegroundColorAttributeName => @textColor }
  end

  def requiredThickness
    digits = Math.log10(lineIndices.size + 1)
    sampleString = "8" * (digits + 2)
    stringSize = sampleString.sizeWithAttributes(@textAttributes)
    [DEFAULT_THICKNESS, 2 * RULER_MARGIN + stringSize.width].max.ceil
  end

  def drawHashMarksAndLabelsInRect(aRect)    
    if @backgroundColor
      @backgroundColor.set
      NSRectFill(bounds)
      NSColor.colorWithCalibratedWhite(0.58, alpha:1.0).set
      NSBezierPath.strokeLineFromPoint(NSMakePoint((NSMaxX(bounds) - 0) / 5, NSMinY(bounds)), toPoint:NSMakePoint(NSMaxX(bounds) - 0.5, NSMaxY(bounds)))
    end

    view = self.clientView

    layoutManager = view.layoutManager
    container = view.textContainer
    text = view.string
    nullRange = NSMakeRange(NSNotFound, 0)

    yinset = view.textContainerInset.height
    visibleRect = self.scrollView.contentView.bounds

    lines = self.lineIndices

    # Find the characters that are currently visible
    glyphRange = layoutManager.glyphRangeForBoundingRect(visibleRect, inTextContainer:container)
    range = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange:nil)

    # Fudge the range a tad in case there is an extra new line at end.
    # It doesn't show up in the glyphs so would not be accounted for.
    range.length += 1

    count = lines.count
    index = 0

    line = lineNumberForCharacterIndex(range.location, inText:text)

    while line < count
      index = lines[line]

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

end