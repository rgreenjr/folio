class ImageCell < NSTextFieldCell

  PADDING = 4
  BADGE_PADDING = 6
  MIN_BADGE_WIDTH = 22

  attr_accessor :image, :badgeCount
  
  def initImageCell(image)
    initTextCell("")
    @image = image
  end
  
  def initTextCell(text)
    super
    self.editable = true
    self.selectable = true      
    self.lineBreakMode = NSLineBreakByTruncatingTail
    self
  end
  
  def image=(image)
    image.scalesWhenResized = true
    image.size = NSSize.new(16, 16)
    super
  end
  
  def badgeColor
    if self.isHighlighted
      NSColor.whiteColor
    else
      NSColor.colorWithDeviceRed(0.60, green:0.65, blue:0.77, alpha:1.0)
    end
  end
  
  def badgeAttributes
    paragraphStyle = NSMutableParagraphStyle.alloc.init
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail
    if self.isHighlighted
      badgeAttributes = {
  	    NSParagraphStyleAttributeName => paragraphStyle,
  	    NSFontAttributeName => NSFont.boldSystemFontOfSize(11.0),
  	    NSForegroundColorAttributeName => NSColor.colorWithDeviceRed(0.60, green:0.65, blue:0.77, alpha:1.0)
  	  }
    else
      badgeAttributes = {
  	    NSParagraphStyleAttributeName => paragraphStyle,
  	    NSFontAttributeName => NSFont.boldSystemFontOfSize(11.0),
  	    NSForegroundColorAttributeName => NSColor.whiteColor
  	  }
    end
    badgeAttributes
  end
  
  def highlightedBadgeAttributes
    unless @highlightedBadgeAttributes
      paragraphStyle = NSMutableParagraphStyle.alloc.init
      paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail
      @badgeAttributes = {
  	    NSParagraphStyleAttributeName => paragraphStyle,
  	    NSFontAttributeName => NSFont.boldSystemFontOfSize(11.0),
  	    NSForegroundColorAttributeName => NSColor.whiteColor
  	  }
	  end
	  @highlightedBadgeAttributes
  end
  
  def badgeString
    @badgeCount.to_s
  end
  
  def badgeSize
    badgeSize = badgeString.sizeWithAttributes(badgeAttributes)
    badgeSize.width = badgeSize.width.ceil + 2 * BADGE_PADDING
    badgeSize.width = [badgeSize.width, MIN_BADGE_WIDTH].max
    badgeSize
  end
  
  def selectWithFrame(cellFrame, inView:controlView, editor:textObj, delegate:anObject, start:selStart, length:selLength)
    imageFrame, cellFrame, badgeFrame = divideFrame(cellFrame) if @image
    # divideFrame(cellFrame) if @image
    super
  end

  def drawWithFrame(cellFrame, inView:controlView)
    if @image

      imageFrame, cellFrame, badgeFrame = divideFrame(cellFrame)
      
      if self.drawsBackground
        backgroundColor.set
        NSRectFill(imageFrame)
      end
      
      if controlView.isFlipped
        delta = ((cellFrame.size.height + imageFrame.size.height) / 2).ceil
      else
        delta = ((cellFrame.size.height - imageFrame.size.height) / 2).ceil
      end      
      imageFrame.origin.y += delta
      
      @image.compositeToPoint(imageFrame.origin, operation:NSCompositeSourceOver)

      drawBadge(badgeFrame) if @badgeCount
    end
    super
  end

  private

  def divideFrame(cellFrame)    
    if @badgeCount

      imageFrame = NSMakeRect(PADDING + cellFrame.origin.x,                          cellFrame.origin.y, @image.size.width,                                              cellFrame.size.height)
      textFrame  = NSMakeRect(PADDING + imageFrame.origin.x + imageFrame.size.width, cellFrame.origin.y, cellFrame.size.width - imageFrame.size.width - badgeSize.width - (4 * PADDING), cellFrame.size.height)
      badgeFrame = NSMakeRect(PADDING + textFrame.origin.x  + textFrame.size.width,  cellFrame.origin.y + 1, badgeSize.width,                                                cellFrame.size.height - 2)

      # puts "cellFrame  #{NSStringFromRect(cellFrame)}"
      # puts "imageFrame #{NSStringFromRect(imageFrame)}"
      # puts "textFrame  #{NSStringFromRect(textFrame)}"
      # puts "badgeFrame #{NSStringFromRect(badgeFrame)}"
      # puts "=========="
      
      # NSColor.redColor.set
      # NSBezierPath.fillRect(imageFrame)
      # 
      # NSColor.greenColor.set
      # NSBezierPath.fillRect(textFrame)
      # 
      # NSColor.blueColor.set
      # NSBezierPath.fillRect(badgeFrame)
      
    else
      imageFrame = NSMakeRect(PADDING + cellFrame.origin.x,                          cellFrame.origin.y, @image.size.width,                                              cellFrame.size.height)
      textFrame  = NSMakeRect(PADDING + imageFrame.origin.x + imageFrame.size.width, cellFrame.origin.y, cellFrame.size.width - imageFrame.size.width - PADDING, cellFrame.size.height)
      badgeFrame = nil
    end
    
    [imageFrame, textFrame, badgeFrame]
  end  
  
  def drawBadge(badgeFrame)
    badgeColor.set
    bezierPath = NSBezierPath.bezierPath
    radius = [10, 0.5 * [NSWidth(badgeFrame), NSHeight(badgeFrame)].min].min
    rect = NSInsetRect(badgeFrame, radius, radius)
    bezierPath.appendBezierPathWithArcWithCenter(NSMakePoint(NSMinX(rect), NSMinY(rect)), radius:radius, startAngle:180.0, endAngle:270.0)
    bezierPath.appendBezierPathWithArcWithCenter(NSMakePoint(NSMaxX(rect), NSMinY(rect)), radius:radius, startAngle:270.0, endAngle:360.0)
    bezierPath.appendBezierPathWithArcWithCenter(NSMakePoint(NSMaxX(rect), NSMaxY(rect)), radius:radius, startAngle:  0.0, endAngle: 90.0)
    bezierPath.appendBezierPathWithArcWithCenter(NSMakePoint(NSMinX(rect), NSMaxY(rect)), radius:radius, startAngle: 90.0, endAngle:180.0)
    bezierPath.closePath
    bezierPath.fill
    rect = NSMakeRect(badgeFrame.origin.x + BADGE_PADDING, badgeFrame.origin.y, badgeFrame.size.width, badgeFrame.size.height)
    badgeString.drawInRect(rect, withAttributes:badgeAttributes)
  end

end