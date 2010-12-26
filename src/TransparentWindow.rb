class TransparentWindow < NSWindow

  def initWithContentRect(contentRect, styleMask:aStyle, backing:bufferingType, defer:flag)
    result = super(contentRect, NSBorderlessWindowMask, NSBackingStoreBuffered, false)
    result.level = NSStatusWindowLevel
    result.backgroundColor = NSColor.clearColor
    result.alphaValue = 1.0
    result.opaque = false
    result.hasShadow = true
    result
  end

  def canBecomeKeyWindow
    true
  end

end
