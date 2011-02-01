class ImageCell < NSTextFieldCell

  PADDING = 4
  IMAGE_SIZE = 16
  MIN_BADGE_WIDTH = 22

  attr_accessor :image, :badgeCount

  def initTextCell(text)
    super
    setEditable(true)
    setSelectable(true)
    setLineBreakMode(NSLineBreakByTruncatingTail)

    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @badgeAttributes = {
      NSParagraphStyleAttributeName => style,
      NSFontAttributeName => NSFont.fontWithName("Helvetica-Bold", size:11)
    }
    
    @baseColor = NSColor.whiteColor
    @highlightColor = NSColor.colorWithDeviceRed(0.60, green:0.65, blue:0.77, alpha:1.0)
    
    calcFontHeight
    
    self
  end
  
  def copyWithZone(zone)
    super
  end

  def image=(image)
    if image
      image.scalesWhenResized = true
      image.size = NSSize.new(IMAGE_SIZE, IMAGE_SIZE)
    end
    super
  end
  
  def font=(aFont)
    super
    calcFontHeight
  end

  def badgeColor
    isHighlighted ? @baseColor : @highlightColor
  end

  def badgeAttributes
    if isHighlighted
      @badgeAttributes[NSForegroundColorAttributeName] = @highlightColor
    else
      @badgeAttributes[NSForegroundColorAttributeName] = @baseColor
    end
    @badgeAttributes
  end

  def badgeString
    @badgeCount.to_s
  end

  def badgeSize
    badgeSize = badgeString.sizeWithAttributes(badgeAttributes)
    badgeSize.width = badgeSize.width.ceil + 2 * PADDING
    badgeSize.width = [badgeSize.width, MIN_BADGE_WIDTH].max
    badgeSize
  end

  def selectWithFrame(cellFrame, inView:controlView, editor:textObj, delegate:anObject, start:selStart, length:selLength)
    imageFrame, cellFrame, badgeFrame = divideFrame(cellFrame) if @image
    super
  end

  def drawWithFrame(cellFrame, inView:controlView)
    if @image
      imageFrame, cellFrame, badgeFrame = divideFrame(cellFrame)
      if drawsBackground
        backgroundColor.set
        NSRectFill(imageFrame)
      end
      imageFrame.origin.y += ((cellFrame.size.height + @image.size.height) / 2).floor
      @image.compositeToPoint(imageFrame.origin, operation:NSCompositeSourceOver)
      drawBadge(badgeFrame) if @badgeCount
    end
    super
  end
  
  def drawInteriorWithFrame(frame, inView:controlView)
    delta = ((frame.size.height - @fontHeight) / 2)
    frame.origin.y += delta
    frame.size.height -= delta
    super
  end

  private

  def divideFrame(frame)
    if @badgeCount
      imageFrame = NSMakeRect(PADDING + frame.origin.x, frame.origin.y, @image.size.width, frame.size.height)
      textFrame  = NSMakeRect(PADDING + imageFrame.origin.x + imageFrame.size.width, frame.origin.y, frame.size.width - imageFrame.size.width - badgeSize.width - (4 * PADDING), frame.size.height)
      badgeFrame = NSMakeRect(PADDING + textFrame.origin.x  + textFrame.size.width,  frame.origin.y + 1, badgeSize.width, frame.size.height - 2)
    else
      imageFrame = NSMakeRect(PADDING + frame.origin.x, frame.origin.y, @image.size.width, frame.size.height)
      textFrame  = NSMakeRect(PADDING + imageFrame.origin.x + imageFrame.size.width, frame.origin.y, frame.size.width - imageFrame.size.width - PADDING, frame.size.height)
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
    drawBadgeLabel(badgeFrame)
  end
  
  def drawBadgeLabel(rect)
    labelSize = badgeString.sizeWithAttributes(@badgeAttributes)
    labelRect = rect
    labelRect.origin.y -= ((rect.size.height - labelSize.height) * 0.5).floor
    badgeString.drawInRect(labelRect, withAttributes:@badgeAttributes)
  end
  
  def calcFontHeight
    @fontHeight = "8".sizeWithAttributes({ NSFontAttributeName => font }).height
  end

end