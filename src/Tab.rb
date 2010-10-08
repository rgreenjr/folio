class Tab

  LABEL_PADDING  = 10.0
  BUTTON_PADDING = 10.0

  attr_accessor :item, :selected, :closeButtonPressed

  def initialize(item)
    @item = item

    begColor  = NSColor.colorWithDeviceRed(0.921, green:0.921, blue:0.921, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.871, green:0.871, blue:0.871, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.820, green:0.820, blue:0.820, alpha:1.0)
    @unselectedGradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], colorSpace:NSColorSpace.genericRGBColorSpace)

    begColor  = NSColor.colorWithDeviceRed(0.734, green:0.734, blue:0.734, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.816, green:0.816, blue:0.816, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.894, green:0.894, blue:0.894, alpha:1.0)
    @selectedGradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], colorSpace:NSColorSpace.genericRGBColorSpace)

    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @labelAttributes = {
	    NSParagraphStyleAttributeName  => style,
	    NSFontAttributeName            => NSFont.systemFontOfSize(11.0),
	    NSForegroundColorAttributeName => NSColor.blackColor
	  }

	  @lineColor = NSColor.colorWithDeviceRed(0.66, green:0.66, blue:0.66, alpha:1.0)
	  
	  @closeImage = NSImage.imageNamed('tab-close.png')
	  @closePressedImage = NSImage.imageNamed('tab-close-pressed.png')
	  
	  @editedClosedImage = NSImage.imageNamed('tab-edited-close.png')
	  @editedPressedImage = NSImage.imageNamed('tab-edited-pressed.png')
  end

  def drawRect(rect)
    drawGradient(rect)
    drawBorder(rect)
    drawLabel(rect)
    drawButton(rect)        
  end

  def closeButtonHit?(point, rect)
    buttonRect = NSMakeRect(rect.origin.x + (BUTTON_PADDING * 0.5), (rect.size.height * 0.5) - (buttonImage.size.height * 0.5), buttonImage.size.width, buttonImage.size.height)
    NSPointInRect(point, buttonRect)
  end

  def selected?
    @selected
  end
  
  private
  
  def drawGradient(rect)
    if @selected
      @selectedGradient.drawInRect(rect, angle:270.0)
    else
      @unselectedGradient.drawInRect(rect, angle:270.0)
    end
  end
  
  def drawBorder(rect)
    # NSFrameRect
    # NSRectEdge mySides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
    #                         NSMinYEdge, NSMaxXEdge};
    # float myGrays[] = {NSBlack, NSBlack, NSWhite, NSWhite,
    #                         NSDarkGray, NSDarkGray};
    # NSRect aRect, clipRect; // Assume exists
    # 
    # aRect = NSDrawTiledRects(aRect, clipRect, mySides, myGrays, 6);
    # [[NSColor grayColor] set];
    # NSRectFill(aRect);
    @lineColor.set
    NSBezierPath.strokeLineFromPoint(CGPoint.new(rect.origin.x + rect.size.width, rect.origin.y), toPoint:CGPoint.new(rect.origin.x + rect.size.width, rect.size.height))
    NSBezierPath.strokeLineFromPoint(CGPoint.new(rect.origin.x, rect.origin.y), toPoint:CGPoint.new(rect.origin.x + rect.size.width, rect.origin.y))
  end
  
  def buttonImage
    if @closeButtonPressed
      @item.edited? ? @editedPressedImage : @closePressedImage
    else
      @item.edited? ? @editedClosedImage : @closeImage
    end
  end
  
  def drawLabel(rect)
    labelRect = NSInsetRect(rect, LABEL_PADDING, 0.0)
    labelRect.origin.x += BUTTON_PADDING
    labelRect.size.width -= BUTTON_PADDING    
    labelSize = @item.name.sizeWithAttributes(@labelAttributes)
    labelRect.origin.y -= ((rect.size.height - labelSize.height) * 0.5).floor
    @item.name.drawInRect(labelRect, withAttributes:@labelAttributes)
  end
  
  def drawButton(rect)
    buttonPoint = CGPoint.new(rect.origin.x + (BUTTON_PADDING * 0.5), ((rect.size.height - buttonImage.size.height) * 0.5).floor)    
    buttonImage.compositeToPoint(buttonPoint, operation:NSCompositeSourceOver)
  end

end
