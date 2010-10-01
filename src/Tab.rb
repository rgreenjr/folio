class Tab
  
  LABEL_PADDING = 10.0
  
  attr_accessor :item, :selected
  
  def initialize(item)
    @item = item

    begColor  = NSColor.colorWithDeviceRed(0.921, green:0.921, blue:0.921, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.871, green:0.871, blue:0.871, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.820, green:0.820, blue:0.820, alpha:1.0)
    @unselectedGradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
    
    begColor  = NSColor.colorWithDeviceRed(0.734, green:0.734, blue:0.734, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.816, green:0.816, blue:0.816, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.894, green:0.894, blue:0.894, alpha:1.0)
    @selectedGradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
    
    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @labelAttributes = {
	    NSParagraphStyleAttributeName => style,
	    NSFontAttributeName => NSFont.boldSystemFontOfSize(11.0),
	    NSForegroundColorAttributeName => NSColor.blackColor
	  }
	  
	  @lineColor = NSColor.colorWithDeviceRed(0.66, green:0.66, blue:0.66, alpha:1.0)
  end
    
  def drawRect(aRect)
    # puts "Tab drawRect = #{NSStringFromRect(aRect)}"
    
    if @selected
      @selectedGradient.drawInRect(aRect, angle:270.0)
    else
      @unselectedGradient.drawInRect(aRect, angle:270.0)
    end    

    @lineColor.set
    bezierPath = NSBezierPath.bezierPath
    bezierPath.lineWidth = 1.0
    offset = aRect.origin.x + aRect.size.width
    bezierPath.moveToPoint(CGPoint.new(offset, aRect.origin.y))
    bezierPath.lineToPoint(CGPoint.new(offset, aRect.size.height))
    bezierPath.stroke
    
    labelRect = NSInsetRect(aRect, LABEL_PADDING, 0.0)
    labelSize = @item.name.sizeWithAttributes(@labelAttributes)
    labelRect.origin.y -= ((aRect.size.height - labelSize.height) * 0.5).floor
    @item.name.drawInRect(labelRect, withAttributes:@labelAttributes)    
  end
  
end
