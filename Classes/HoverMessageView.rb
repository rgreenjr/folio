class HoverMessageView < NSView

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
  
  def self.backgroundLeftImage
    @backgroundLeftImage ||= NSImage.imageNamed('bubble-background-left.png')
  end
  
  def self.backgroundRightImage
    @backgroundRightImage ||= NSImage.imageNamed('bubble-background-right.png')
  end
  
  def self.backgroundMiddleImage
    @backgroundMiddleImage ||= NSImage.imageNamed('bubble-background-middle.png')
  end
  
  def message=(message)
    @message = message
    needsDisplay = true
  end

  def drawRect(rect)
    drawBackgroundImages(rect)
    drawMessage(rect)
  end
  
  private
  
  def drawBackgroundImages(rect)
    # draw left image
    HoverMessageView.backgroundLeftImage.drawAtPoint(rect.origin, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)
    
    # draw middle image
    backgroundMiddleRect = NSMakeRect(HoverMessageView.backgroundLeftImage.size.width, 0, rect.size.width - (2 * HoverMessageView.backgroundRightImage.size.width), rect.size.height)
    HoverMessageView.backgroundMiddleImage.drawInRect(backgroundMiddleRect, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)

    # draw right image
    HoverMessageView.backgroundRightImage.drawAtPoint(NSMakePoint(rect.size.width - HoverMessageView.backgroundRightImage.size.width, 0), fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)
  end

  def drawMessage(rect)
    messageRect = NSInsetRect(rect, MESSAGE_PADDING, 0.0)
    # messageRect.origin.x += MESSAGE_PADDING
    # messageRect.size.width -= MESSAGE_PADDING    
    messageSize = @message.sizeWithAttributes(HoverMessageView.messageAttributes)
    messageRect.origin.y -= ((rect.size.height - messageSize.height) * 0.5).floor
    @message.drawInRect(messageRect, withAttributes:HoverMessageView.messageAttributes)
  end

end