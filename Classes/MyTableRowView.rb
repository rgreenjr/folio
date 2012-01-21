class MyTableRowView < NSTableRowView
  
  BLUE_TEXTURE_COLOR  = NSColor.colorWithPatternImage(NSImage.imageNamed("BlueTexture.png"))
  BLUE_TEXTURE_ENDCAP = NSImage.imageNamed("BlueTextureEndcap.png")
  
  TOP_LINE_COLOR          = NSColor.colorWithCalibratedRed(0.292, green:0.571, blue:0.837, alpha:1.0)
  INSET_LINE_COLOR        = NSColor.colorWithCalibratedRed(0.378, green:0.662, blue:0.894, alpha:1.0)
  BEGIN_COLOR             = NSColor.colorWithCalibratedRed(0.344, green:0.621, blue:0.865, alpha:1.0)
  MID_COLOR               = NSColor.colorWithCalibratedRed(0.271, green:0.552, blue:0.837, alpha:1.0)
  END_COLOR               = NSColor.colorWithCalibratedRed(0.192, green:0.463, blue:0.796, alpha:1.0)
  BOTTOM_LINE_COLOR       = NSColor.colorWithCalibratedRed(0.097, green:0.343, blue:0.654, alpha:1.0)
  BACKGROUND_GRADIENT     = NSGradient.alloc.initWithColors([BEGIN_COLOR, MID_COLOR, END_COLOR], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
  
  TOP_LINE_ALT_COLOR      = NSColor.colorWithCalibratedRed(0.679, green:0.724, blue:0.809, alpha:1.0)
  INSET_LINE_ALT_COLOR    = NSColor.colorWithCalibratedRed(0.711, green:0.750, blue:0.847, alpha:1.0)
  BEGIN_ALT_COLOR         = NSColor.colorWithCalibratedRed(0.679, green:0.722, blue:0.828, alpha:1.0)
  MID_ALT_COLOR           = NSColor.colorWithCalibratedRed(0.608, green:0.658, blue:0.777, alpha:1.0)
  END_ALT_COLOR           = NSColor.colorWithCalibratedRed(0.548, green:0.600, blue:0.727, alpha:1.0)
  BOTTOM_LINE_ALT_COLOR   = NSColor.colorWithCalibratedRed(0.506, green:0.557, blue:0.677, alpha:1.0)
  BACKGROUND_ALT_GRADIENT = NSGradient.alloc.initWithColors([BEGIN_ALT_COLOR, MID_ALT_COLOR, END_ALT_COLOR], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)

  def drawBackgroundInRect(rect)
    BLUE_TEXTURE_COLOR.set
    NSRectFill(rect)
    BLUE_TEXTURE_ENDCAP.drawInRect([bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height], fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0)
  end

  def drawSelectionInRect(rect)
    # endcapRect = [bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height]    
    if isEmphasized
      drawSelectionRect(bounds, BACKGROUND_GRADIENT, TOP_LINE_COLOR, INSET_LINE_COLOR, BOTTOM_LINE_COLOR)
    else
      drawSelectionRect(bounds, BACKGROUND_ALT_GRADIENT, TOP_LINE_ALT_COLOR, INSET_LINE_ALT_COLOR, BOTTOM_LINE_ALT_COLOR)
    end
  end

  def interiorBackgroundStyle
    # make text white when app isn't active window
    isSelected ? NSBackgroundStyleDark : super
  end
  
  private
  
  def drawSelectionRect(rect, backgroundColor, topLineColor, insetLineColor, bottomLineColor)
    backgroundColor.drawInRect(rect, angle:90.0)
        
    topLineColor.set
    NSBezierPath.strokeLineFromPoint(rect.origin, toPoint:[rect.size.width, rect.origin.y])
    
    insetLineColor.set
    NSBezierPath.strokeLineFromPoint([rect.origin.x, rect.origin.y + 1.5], toPoint:[rect.size.width, rect.origin.y + 1.5])

    bottomLineColor.set
    NSBezierPath.strokeLineFromPoint([rect.origin.x, rect.size.height], toPoint:[rect.size.width, rect.size.height])
  end
  
end

