class HoverWindow < NSWindow

  attr_accessor :hoverView

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