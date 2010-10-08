class HeaderView < NSView

  def initWithFrame(frameRect)
    super
    @title = ""
    @image = NSImage.imageNamed("table-header-bg.png")
    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @textAttributes = {
      NSParagraphStyleAttributeName  => style,
      NSFontAttributeName            => NSFont.systemFontOfSize(11.0),
      NSForegroundColorAttributeName => NSColor.blackColor
    }
    self
  end
  
  def title=(title)
    @title = title
    setNeedsDisplay true
  end

  def drawRect(frame)
    # draw background image
    imageRect = NSZeroRect
    imageRect.size = @image.size        
    @image.drawInRect(frame, fromRect:imageRect, operation:NSCompositeSourceOver, fraction:1.0)

    # draw black text centered, but offset down-left
    offset = 0.5
    @textAttributes["NSColor"] = NSColor.blackColor
    centeredRect = frame
    centeredRect.size = @title.sizeWithAttributes(@textAttributes)
    centeredRect.origin.x += ((frame.size.width - centeredRect.size.width)   / 2.0) - offset
    centeredRect.origin.y  = ((frame.size.height - centeredRect.size.height) / 2.0) + offset
    @title.drawInRect(centeredRect, withAttributes:@textAttributes)

    # draw white text centered
    @textAttributes["NSColor"] = NSColor.whiteColor
    centeredRect.origin.x += offset
    centeredRect.origin.y -= offset
    @title.drawInRect(centeredRect, withAttributes:@textAttributes)
  end
  
end