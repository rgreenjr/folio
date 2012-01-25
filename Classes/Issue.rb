class Issue

  @@insetColor      = NSColor.colorWithCalibratedRed(0.55, green:0.82, blue:0.54, alpha:1.0)
  @@borderColor     = NSColor.colorWithCalibratedRed(0.09, green:0.6,  blue:0.07, alpha:1.0)
  @@backgroundColor = NSColor.colorWithCalibratedRed(0.4, green:0.76, blue:0.38, alpha:1.0)

  attr_accessor :message
  attr_accessor :lineNumber
  attr_accessor :informativeText

  def initialize(message, lineNumber=nil, informativeText='')
    @message = message
    @lineNumber = lineNumber
    @informativeText = informativeText
  end
  
  def displayString
    lineNumber ? "       #{lineNumber + 1}:  #{message}" : "       #{message}"
  end
  
  def <=>(other)
    lineNumber && other.lineNumber ? lineNumber <=> other.lineNumber : 1
  end
  
  def drawRect(rect)
    # draw background
    @@backgroundColor.set
    NSRectFill(rect)
    
    # draw top border
    drawPath(rect.origin.x, rect.origin.y + 0.5, rect.size.width, rect.origin.y + 0.5, @@borderColor)
        
    # draw top border inset
    drawPath(rect.origin.x, rect.origin.y + 1.5, rect.size.width, rect.origin.y + 1.5, @@insetColor)
    
    # # draw bottom border
    drawPath(rect.origin.x, rect.origin.y + rect.size.height - 0.5, rect.size.width, rect.origin.y + rect.size.height - 0.5, @@borderColor)
  end

  private

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
