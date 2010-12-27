class LineNumberMarker < NSRulerMarker

  CORNER_RADIUS     = 3.0
  MARKER_HEIGHT     = 13.0

  attr_accessor :lineNumber, :message, :textAttributes

  def initWithRulerView(rulerView, lineNumber:lineNumber, message:message)
    initWithRulerView(rulerView, markerLocation:0.0, image:blueImage, imageOrigin:NSMakePoint(0, MARKER_HEIGHT / 2))
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
  def blueImage
    unless @blueImage
      rep = NSCustomImageRep.alloc.initWithDrawSelector("drawMarkerImageIntoRep:", delegate:self)
      rep.size = NSMakeSize(44, MARKER_HEIGHT)
      @blueImage = NSImage.alloc.initWithSize(rep.size)
      @blueImage.addRepresentation(rep)
    end
    @blueImage
  end
  
  # callback method used to create blue marker image dynamically
  def drawMarkerImageIntoRep(rep)
    rect = NSMakeRect(1.0, 2.0, rep.size.width - 2.0, rep.size.height - 3.0)

    path = NSBezierPath.bezierPath
    path.moveToPoint(NSMakePoint(NSMaxX(rect), NSMinY(rect) + NSHeight(rect) / 2))
    path.lineToPoint(NSMakePoint(NSMaxX(rect) - 5.0, NSMaxY(rect)))

    path.appendBezierPathWithArcWithCenter(NSMakePoint(NSMinX(rect) + CORNER_RADIUS, NSMaxY(rect) - CORNER_RADIUS), radius:CORNER_RADIUS, startAngle:90, endAngle:180)

    path.appendBezierPathWithArcWithCenter(NSMakePoint(NSMinX(rect) + CORNER_RADIUS, NSMinY(rect) + CORNER_RADIUS), radius:CORNER_RADIUS, startAngle:180, endAngle:270)
    path.lineToPoint(NSMakePoint(NSMaxX(rect) - 5.0, NSMinY(rect)))
    path.closePath

    NSColor.colorWithCalibratedRed(0.003, green:0.56, blue:0.85, alpha:1.0).set
    path.fill

    # NSColor.colorWithCalibratedRed(0, green:0.44, blue:0.8, alpha:1.0).set

    path.lineWidth = 2.0
    path.stroke
  end

end
