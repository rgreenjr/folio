class LineNumberRuler < NSRulerView

  DEFAULT_THICKNESS	= 22.0
  RULER_MARGIN		  = 5.0

  def initWithScrollView(scrollView)
    initWithScrollView(scrollView, orientation:NSVerticalRuler)
    setClientView(scrollView.documentView)
    ctr = NSNotificationCenter.defaultCenter
    ctr.addObserver(self, selector:'textDidChange:', name:NSTextStorageDidProcessEditingNotification, object:clientView.textStorage)
    @issueHash = {}
    @textAttributes = {
      NSFontAttributeName => NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize)),
      NSForegroundColorAttributeName => NSColor.grayColor
    }
    updateLineIndices
    self
  end
  
  def issueHash=(issueHash)
    @issueHash = issueHash
    setNeedsDisplay true
  end
  
  def clearIssues
    @issueHash = {}
    setNeedsDisplay true
  end

  def textDidChange(notification)
    updateLineIndices
    setNeedsDisplay true
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

    # remove any tracking areas
    trackingAreas.each { |area| removeTrackingArea(area) }
    
    # close HUD window
    closeHUD

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

          # check if there is a issue to draw for this line number
					issue = @issueHash[line]
					
					if issue
					  
					  # update issue width incase ruler width changed
					  issue.image.size = NSMakeSize(ruleThickness, issue.image.size.height)
					  
            # issueImage = issue.image
						issueRect = NSMakeRect(0.0, 0.0, issue.image.size.width - 1.0, issue.image.size.height)

						# issue is flush right and centered vertically within the line.
						issueRect.origin.x = 0#NSWidth(bounds) - issue.image.size.width - 1.0
						issueRect.origin.y = ypos + NSHeight(rects[0]) / 2.0 - issue.imageOrigin.y

            fromRect = NSMakeRect(0, 0, issue.image.size.width, issue.image.size.height)
						issue.image.drawInRect(issueRect, fromRect:fromRect, operation:NSCompositeSourceOver, fraction:1.0)
						
            # add tracking area for this issue
						trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
						trackingArea = NSTrackingArea.alloc.initWithRect(issueRect, options:trackingOptions, owner:self, userInfo:nil)
            addTrackingArea(trackingArea)
					end

          if issue
            labelText.drawInRect(textRect, withAttributes:issue.textAttributes)
          else
            labelText.drawInRect(textRect, withAttributes:@textAttributes)
          end
          
        end
      end

      break if index > NSMaxRange(range)
      line += 1
    end
    
  end
  
  def lineNumberForLocation(location)
  	visibleRect = scrollView.contentView.bounds
  	location += NSMinY(visibleRect)

		nullRange = NSMakeRange(NSNotFound, 0)
		layoutManager = clientView.layoutManager
		container = clientView.textContainer
		count = @lineIndices.count
    line = 0
    
		while line < count
			index = @lineIndices[line]

      rectCount = Pointer.new(:ulong_long)
			rects = layoutManager.rectArrayForCharacterRange(NSMakeRange(index, 0), 
			    withinSelectedCharacterRange:nullRange, inTextContainer:container, rectCount:rectCount)

      i = 0
			while i < rectCount[0]
				if location >= NSMinY(rects[i]) && location < NSMaxY(rects[i])
					return line + 1
				end
				i += 1
			end
			line += 1
		end
  	
  	NSNotFound
  end
  
  # returns the logical (wrapped) line of the current caret location
  def logicalLineAtInsertion
    lineCount = index = 0
    lineRange = Pointer.new(NSRange.type)
    layoutManager = clientView.layoutManager
    glyphCount = NSMaxRange(layoutManager.glyphRangeForCharacterRange(NSMakeRange(0, clientView.selectedRange.location), actualCharacterRange:nil))
    while index < glyphCount
      layoutManager.lineFragmentRectForGlyphAtIndex(index, effectiveRange:lineRange)
      index = NSMaxRange(lineRange[0])
      lineCount += 1
    end
    lineCount
  end
  
  # returns the physical (actual) line number for the current caret location
  def physicalLineAtInsertion
    lineNumberForCharacterIndex(clientView.selectedRange.location, inText:clientView.string) + 1
  end

  # returns the character index of line corresponding to line number
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
  
  # returns the index of the logical (wrapped) line corresponding to the physical line index return by indexOfPhysicalLine
  def logicalLineIndexAtPhysicalCharacterIndex(physicalIndex)
    index = lineCount = 0
    lineRange = Pointer.new(NSRange.type)
    layoutManager = clientView.layoutManager
    glyphCount = NSMaxRange(layoutManager.glyphRangeForCharacterRange(NSMakeRange(0, physicalIndex), actualCharacterRange:nil))
    while index < glyphCount
      layoutManager.lineFragmentRectForGlyphAtIndex(index, effectiveRange:lineRange)
      index = NSMaxRange(lineRange[0])
      lineCount += 1
    end
    index
  end

  # places the caret at the start of the specified line and scrolls to make it visible
  def gotoLine(lineNumber)
    insertionLocation = logicalLineIndexAtPhysicalCharacterIndex(indexOfPhysicalLine(lineNumber))
    clientView.selectedRange = NSMakeRange(insertionLocation, 0)
    clientView.scrollRangeToVisible(NSMakeRange(insertionLocation, 0))
  end
  
  def acceptsFirstResponder
    false
  end
  
  def mouseEntered(event)
    # return if we are already displaying the window
    return if @hudWindow
    
    issue = issueForEvent(event)
    if issue
      screenPoint = window.convertBaseToScreen(convertPoint(event.trackingArea.rect.origin, toView:nil))
      screenPoint.x += 10.0
      screenPoint.y += 5.0
      showHUDWindowForIssue(issue, screenPoint)
    end
  end
  
  def issueForEvent(event)
    location = convertPoint(event.locationInWindow, fromView:nil)
    line = lineNumberForLocation(location.y)
    return nil if line == NSNotFound
    @issueHash[line - 1]
  end
  
  def showHUDWindowForIssue(issue, location)
    size = HUDMessageView.sizeForMessage(issue.message)    
    contentRect = NSMakeRect(location.x, location.y, size.width, 24.0);    
    @hudWindow = HUDWindow.alloc.initWithContentRect(contentRect, message:issue.message)
    @hudWindow.orderFront(NSApp)    
  end
  
  def mouseExited(event)
    closeHUD
  end
  
  # selects the corresponding line
  def mouseDown(event)
    closeHUD
    location = convertPoint(event.locationInWindow, fromView:nil)
    lineNumber = lineNumberForLocation(location.y)
    selectLineNumber(lineNumber) unless lineNumber == NSNotFound
  end
  
  def selectLineNumber(lineNumber)
    gotoLine(lineNumber)
    paragraphRange = clientView.string.paragraphRangeForRange(clientView.selectedRange)
    clientView.setSelectedRange(paragraphRange)
    # window.makeFirstResponder(clientView)
  end

  private

  def closeHUD
    if @hudWindow
      @hudWindow.close
      @hudWindow = nil
    end
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