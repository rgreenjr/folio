class Issue

  IMAGE_HEIGHT = 15.0

  attr_accessor :lineNumber, :message, :textAttributes, :imageOrigin

  def initialize(message, lineNumber=nil)
    @message = message
    @lineNumber = lineNumber
    @textAttributes = {
      NSFontAttributeName => NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSMiniControlSize)),
      NSForegroundColorAttributeName => NSColor.whiteColor
    }
    self
  end
  
  def displayString
    lineNumber ? "#{"%10d" % (lineNumber + 1)}:  #{message}" : "          #{message}"
  end
  
  def <=>(other)
    lineNumber && other.lineNumber ? lineNumber <=> other.lineNumber : 1
  end
  
  # creates the image shared by all issues
  def image
    unless @image
      rep = NSCustomImageRep.alloc.initWithDrawSelector("drawIssueImageIntoRep:", delegate:self)
      rep.size = NSMakeSize(44, IMAGE_HEIGHT)
      @image = NSImage.alloc.initWithSize(rep.size)
      @image.addRepresentation(rep)
      @imageOrigin = NSMakePoint(0, IMAGE_HEIGHT / 2)
    end
    @image
  end

  private

  # callback method used to create image dynamically
  def drawIssueImageIntoRep(rep)
    insetColor      = NSColor.colorWithCalibratedRed(0.55, green:0.82, blue:0.54, alpha:1.0)
    borderColor     = NSColor.colorWithCalibratedRed(0.09, green:0.6,  blue:0.07, alpha:1.0)
    backgroundColor = NSColor.colorWithCalibratedRed(0.4,  green:0.76, blue:0.38, alpha:1.0)

    # draw background
    backgroundColor.set
    rect = NSMakeRect(0, 0, rep.size.width + 10, rep.size.height + 10)
    NSRectFill(rect)
    
    # draw top border
    drawPath(0, 0.5, rep.size.width, 0.5, borderColor)
        
    # draw top border inset
    drawPath(0, 1.5, rep.size.width, 1.5, insetColor)
    
    # draw bottom border
    drawPath(0, rep.size.height - 0.5, rep.size.width, rep.size.height - 0.5, borderColor)
  end
  
  def drawPath(x, y, width, height, color)
    path = NSBezierPath.bezierPath
    color.set
    path.lineWidth = 1.0
    path.moveToPoint([x, y])
    path.lineToPoint([width, height])
    path.closePath
    path.stroke
  end

end
