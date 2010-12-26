class HUDWindow < NSWindow

  attr_accessor :hudView

  def initWithContentRect(contentRect, message:message)
    initWithContentRect(contentRect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
    level = NSStatusWindowLevel
    backgroundColor = NSColor.clearColor
    alphaValue = 1.0
    opaque = false
    hasShadow = true
    @hudView = HUDMessageView.alloc.initWithFrame(contentRect)
    setContentView(@hudView)
    @hudView.message = message
    self
  end

  def canBecomeKeyWindow
    false
  end

end