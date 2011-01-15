class ImageCell < NSTextFieldCell

  PADDING = 4
  MIN_BADGE_WIDTH = 22

  attr_accessor :image, :badgeCount

  def initImageCell(image)
    initTextCell("")
    @image = image
  end

  def initTextCell(text)
    super
    editable = true
    selectable = true
    lineBreakMode = NSLineBreakByTruncatingTail

    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @badgeAttributes = {
      NSParagraphStyleAttributeName => style,
      NSFontAttributeName => badgeFont = NSFont.fontWithName("Helvetica-Bold", size:11)
    }
    
    @baseColor = NSColor.whiteColor
    @highlightColor = NSColor.colorWithDeviceRed(0.60, green:0.65, blue:0.77, alpha:1.0)

    self
  end

  def image=(image)
    image.scalesWhenResized = true
    image.size = NSSize.new(16, 16)
    super
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
      imageFrame = NSMakeRect(PADDING + cellFrame.origin.x, cellFrame.origin.y, @image.size.width, cellFrame.size.height)
      textFrame  = NSMakeRect(PADDING + imageFrame.origin.x + imageFrame.size.width, cellFrame.origin.y, cellFrame.size.width - imageFrame.size.width - badgeSize.width - (4 * PADDING), cellFrame.size.height)
      badgeFrame = NSMakeRect(PADDING + textFrame.origin.x  + textFrame.size.width,  cellFrame.origin.y + 1, badgeSize.width, cellFrame.size.height - 2)
    else
      imageFrame = NSMakeRect(PADDING + cellFrame.origin.x, cellFrame.origin.y, @image.size.width, cellFrame.size.height)
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
    drawBadgeLabel(badgeFrame)
  end
  
  def drawBadgeLabel(rect)
    labelSize = badgeString.sizeWithAttributes(@badgeAttributes)
    labelRect = rect
    labelRect.origin.y -= ((rect.size.height - labelSize.height) * 0.5).floor
    badgeString.drawInRect(labelRect, withAttributes:@badgeAttributes)
  end


end