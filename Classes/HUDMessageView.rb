class HUDMessageView < NSView

  RADIUS          = 5.0
  MESSAGE_PADDING = 5.0

  attr_accessor :message

  def self.sizeForMessage(msg)
    size = msg.sizeWithAttributes(messageAttributes)
    size.width += MESSAGE_PADDING * 3
    size
  end
  
  def self.messageAttributes
    unless @messageAttributes
      style = NSMutableParagraphStyle.alloc.init
      style.alignment = NSCenterTextAlignment
      style.lineBreakMode = NSLineBreakByTruncatingTail
      @messageAttributes = {
        NSParagraphStyleAttributeName  => style,
        NSFontAttributeName            => NSFont.systemFontOfSize(11.0),
        NSForegroundColorAttributeName => NSColor.whiteColor
      }
    end
    @messageAttributes
  end
  
  def message=(message)
    @message = message
    needsDisplay = true
  end

  def drawRect(rect)      
    bgRect = rect
    minX = NSMinX(bgRect)
    midX = NSMidX(bgRect)
    maxX = NSMaxX(bgRect)
    minY = NSMinY(bgRect)
    midY = NSMidY(bgRect)
    maxY = NSMaxY(bgRect)

    bgPath = NSBezierPath.bezierPath

    # Bottom edge and bottom-right curve
    bgPath.moveToPoint(NSMakePoint(midX, minY))
    bgPath.appendBezierPathWithArcFromPoint(NSMakePoint(maxX, minY), toPoint:NSMakePoint(maxX, midY), radius:RADIUS)

    # Right edge and top-right curve
    bgPath.appendBezierPathWithArcFromPoint(NSMakePoint(maxX, maxY), toPoint:NSMakePoint(midX, maxY), radius:RADIUS)

    # Top edge and top-left curve
    bgPath.appendBezierPathWithArcFromPoint(NSMakePoint(minX, maxY), toPoint:NSMakePoint(minX, midY), radius:RADIUS)

    # Left edge and bottom-left curve
    bgPath.appendBezierPathWithArcFromPoint(bgRect.origin, toPoint:NSMakePoint(midX, minY), radius:RADIUS)
    bgPath.closePath

    NSColor.colorWithCalibratedWhite(0.0, alpha:0.85).set
    bgPath.fill

    messageRect = NSInsetRect(rect, MESSAGE_PADDING, 0.0)
    # messageRect.origin.x += MESSAGE_PADDING
    messageRect.size.width -= MESSAGE_PADDING    
    messageSize = @message.sizeWithAttributes(HUDMessageView.messageAttributes)
    messageRect.origin.y -= ((rect.size.height - messageSize.height) * 0.5).floor
    @message.drawInRect(messageRect, withAttributes:HUDMessageView.messageAttributes)
  end

end