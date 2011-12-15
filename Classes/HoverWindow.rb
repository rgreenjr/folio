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
    window = initWithContentRect(contentRect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
    window.backgroundColor = NSColor.clearColor
    window.level = NSStatusWindowLevel
    window.alphaValue = 0.95
    window.opaque = false
    window.hasShadow = true
    window.hidesOnDeactivate = true
    @hoverView = HoverMessageView.alloc.initWithFrame(contentRect)
    @hoverView.message = message
    window.setContentView(@hoverView)
    window
  end

  def canBecomeKeyWindow
    false
  end

end