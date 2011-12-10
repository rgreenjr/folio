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
      
      # center text
      style = NSMutableParagraphStyle.alloc.init
      style.alignment = NSCenterTextAlignment
      style.lineBreakMode = NSLineBreakByTruncatingTail
      
      # add embossing shadow
      shadow = NSShadow.alloc.init
      shadow.shadowColor = NSColor.blackColor
      shadow.shadowOffset = NSMakeSize(0.0, 1.0)
      
      @messageAttributes = {
        NSParagraphStyleAttributeName  => style,
        NSFontAttributeName            => NSFont.systemFontOfSize(11.0),
        NSForegroundColorAttributeName => NSColor.whiteColor,
        NSShadowAttributeName => shadow
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
    NSColor.clearColor.set
    NSRectFill(frame)
    drawBackgroundImages(rect)
    drawMessage(rect)
  end
  
  private
  
  def drawBackgroundImages(rect)
    # draw left image
    HoverMessageView.backgroundLeftImage.compositeToPoint(rect.origin, operation:NSCompositeSourceOver)
    
    # draw middle image
    backgroundMiddleRect = NSMakeRect(HoverMessageView.backgroundLeftImage.size.width, 0, rect.size.width - (2 * HoverMessageView.backgroundRightImage.size.width), rect.size.height)
    HoverMessageView.backgroundMiddleImage.drawInRect(backgroundMiddleRect, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)

    # draw right image
    HoverMessageView.backgroundRightImage.compositeToPoint(NSMakePoint(rect.size.width - HoverMessageView.backgroundRightImage.size.width, 0), operation:NSCompositeSourceOver)
  end

  def drawMessage(rect)
    messageRect = NSInsetRect(rect, MESSAGE_PADDING, 0.0)
    messageSize = @message.sizeWithAttributes(HoverMessageView.messageAttributes)
    messageRect.origin.y -= ((rect.size.height - messageSize.height) * 0.5).floor    
    @message.drawInRect(messageRect, withAttributes:HoverMessageView.messageAttributes)
  end

end