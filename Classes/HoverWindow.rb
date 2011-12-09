class HoverWindow < NSWindow
  
  VERTICAL_OFFSET   = 4
  HORIZONTAL_OFFSET = 27

  attr_accessor :hoverView
  
  def self.showWindowForIssue(issue, atLocation:location)
    size = HoverMessageView.sizeForMessage(issue.message)    
    contentRect = NSMakeRect(location.x + HORIZONTAL_OFFSET, location.y + VERTICAL_OFFSET, size.width, 24.0);    
    hoverWindow = HoverWindow.alloc.initWithContentRect(contentRect, message:issue.message)
    hoverWindow.orderFront(NSApp)
    hoverWindow
  end

  def initWithContentRect(contentRect, message:message)
    initWithContentRect(contentRect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
    level = NSStatusWindowLevel
    backgroundColor = NSColor.clearColor
    alphaValue = 1.0
    opaque = false
    hasShadow = true
    @hoverView = HoverMessageView.alloc.initWithFrame(contentRect)
    setContentView(@hoverView)
    @hoverView.message = message
    self
  end

  def canBecomeKeyWindow
    false
  end

end