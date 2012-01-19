class LogoView < NSView
  
  def initWithFrame(frameRect)
    super
    @backgroundColor = NSColor.colorWithPatternImage(NSImage.imageNamed("LogoTile.png"))
    self
  end
  
  def drawRect(rect)
    @backgroundColor.set
    NSRectFill(rect)
  end
  
end