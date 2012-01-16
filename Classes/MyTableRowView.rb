class MyTableRowView < NSTableRowView

  BACKGROUND     = NSImage.imageNamed("SelectionBackground.png")
  ENDCAP         = NSImage.imageNamed("SelectionEndcap.png")
  
  BACKGROUND_ALT = NSImage.imageNamed("SelectionAltBackground.png")
  ENDCAP_ALT     = NSImage.imageNamed("SelectionAltEndcap.png")

  def drawBackgroundInRect(rect)
    MyOutlineView::BLUE_TEXTURE_COLOR.set
    NSRectFill(rect)
    endcapRect = NSMakeRect(bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height)
    MyOutlineView::BLUE_TEXTURE_ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0)
  end

  def drawSelectionInRect(dirtyRect)  
    super
    endcapRect = NSMakeRect(bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height)
    if isEmphasized
      BACKGROUND.drawInRect(bounds, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
      ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
    else
      BACKGROUND_ALT.drawInRect(bounds, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
      ENDCAP_ALT.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
    end
  end
  
  def interiorBackgroundStyle
    # so white text will be used when app isn't active window
    isSelected ? NSBackgroundStyleDark : super
  end
  
end

