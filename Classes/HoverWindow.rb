class HoverWindow < NSWindow
  
  VERTICAL_OFFSET   = 7
  HORIZONTAL_OFFSET = 27
  WINDOW_HEIGHT     = 24

  attr_accessor :hoverView
  
  def self.showWindowForIssue(issue, atLocation:location)
    size = HoverMessageView.sizeForMessage(issue.message)    
    contentRect = NSMakeRect(location.x + HORIZONTAL_OFFSET, location.y + VERTICAL_OFFSET, size.width, WINDOW_HEIGHT);    
    hoverWindow = HoverWindow.alloc.initWithContentRect(contentRect, message:issue.message)
    hoverWindow.orderFront(NSApp)
    hoverWindow
  end

  def initWithContentRect(contentRect, message:message)
    result = initWithContentRect(contentRect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
    result.setBackgroundColor(NSColor.clearColor)
    result.setLevel(NSStatusWindowLevel)
    result.setAlphaValue(0.95)
    result.setOpaque(false)
    result.setHasShadow(true)
    @hoverView = HoverMessageView.alloc.initWithFrame(contentRect)
    @hoverView.message = message
    result.setContentView(@hoverView)
    result
  end

  def canBecomeKeyWindow
    false
  end

end