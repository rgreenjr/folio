class LineNumberMarker < NSRulerMarker

  MARKER_HEIGHT = 13.0

  attr_accessor :lineNumber, :message, :textAttributes

  def initWithRulerView(rulerView, lineNumber:lineNumber, message:message)
    initWithRulerView(rulerView, markerLocation:0.0, image:markerImage, imageOrigin:NSMakePoint(0, MARKER_HEIGHT / 2))
    @lineNumber = lineNumber
    @message = message
    @textAttributes = { 
      NSFontAttributeName => NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize)), 
      NSForegroundColorAttributeName => NSColor.whiteColor
    }
    self
  end
  
  private
  
  # creates the blue marker image shared by all markers
  def markerImage
    unless @markerImage
      rep = NSCustomImageRep.alloc.initWithDrawSelector("drawMarkerImageIntoRep:", delegate:self)
      rep.size = NSMakeSize(44, MARKER_HEIGHT)
      @markerImage = NSImage.alloc.initWithSize(rep.size)
      @markerImage.addRepresentation(rep)
    end
    @markerImage
  end
  
  # callback method used to create blue marker image dynamically
  def drawMarkerImageIntoRep(rep)
    p rep.size
    NSColor.colorWithCalibratedRed(0.4, green:0.76, blue:0.38, alpha:1.0).set
    rect = NSMakeRect(0, 0, rep.size.width + 10, rep.size.height + 10)
    NSRectFill(rect)
    

    # # draw top border
    path = NSBezierPath.bezierPath
    NSColor.colorWithCalibratedRed(0.09, green:0.6, blue:0.07, alpha:1.0).set
    path.lineWidth = 1.0
    path.moveToPoint([0, 0.5])
    path.lineToPoint([rep.size.width, 0.5])
    path.closePath
    path.stroke
    
    # draw bottom border
    path = NSBezierPath.bezierPath
    NSColor.colorWithCalibratedRed(0.09, green:0.6, blue:0.07, alpha:1.0).set
    path.lineWidth = 1.0
    path.moveToPoint([0, rep.size.height - 0.5])
    path.lineToPoint([rep.size.width, rep.size.height - 0.5])
    path.closePath
    path.stroke
    
    # # draw top border inset
    path = NSBezierPath.bezierPath
    NSColor.colorWithCalibratedRed(0.55, green:0.82, blue:0.54, alpha:1.0).set
    path.lineWidth = 1.0
    path.moveToPoint([0, 1.5])
    path.lineToPoint([rep.size.width, 1.5])
    path.closePath    
    path.stroke
  end

end
