class HeaderView < NSView
  
  TITLE_PADDING = 10.0

  def initWithFrame(frameRect)
    super
    @title = "untitled"
    @image = NSImage.imageNamed("table-header-bg1.png")
    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @textAttributes = {
      NSParagraphStyleAttributeName => style,
      NSFontAttributeName => NSFont.systemFontOfSize(11.0),
    }
    self
  end
  
  def title=(title)
    if title
      @title = title 
      setNeedsDisplay true
    end
  end

  def drawRect(rect)
    drawBackground(rect)
    drawLabel(rect, NSColor.darkGrayColor, 0.5)
    drawLabel(rect, NSColor.whiteColor)
  end
  
  private

  def drawBackground(rect)
    imageRect = NSMakeRect(0, 0, @image.size.width, @image.size.height)
    @image.drawInRect(rect, fromRect:imageRect, operation:NSCompositeSourceOver, fraction:1.0)
  end

  def drawLabel(rect, color, offset=0.0)    
    @textAttributes[NSForegroundColorAttributeName] = color
    titleSize = @title.sizeWithAttributes(@textAttributes)
    titleRect = NSInsetRect(rect, TITLE_PADDING, 0.0)
    titleRect.origin.y -= ((rect.size.height - titleSize.height) * 0.5).floor
    titleRect.origin.x += offset 
    titleRect.origin.y -= offset 
    @title.drawInRect(titleRect, withAttributes:@textAttributes)
  end
  
end