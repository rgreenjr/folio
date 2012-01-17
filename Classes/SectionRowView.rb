class SectionRowView < NSTableRowView
  
  BACKGROUND = NSImage.imageNamed("SectionBackground.png")
  ENDCAP     = NSImage.imageNamed("SectionEndcap.png")
  
  BLUE_TEXTURE_COLOR  = NSColor.colorWithPatternImage(NSImage.imageNamed("BlueTexture.png"))
  BLUE_TEXTURE_ENDCAP = NSImage.imageNamed("BlueTextureEndcap.png")
  
  def drawBackgroundInRect(rect)
		BLUE_TEXTURE_COLOR.set
    NSRectFill(rect)
    endcapRect = NSMakeRect(rect.size.width - 2, rect.origin.y, 2, rect.size.height)
    BLUE_TEXTURE_ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0)
    
    # BACKGROUND.drawInRect(bounds, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0, respectFlipped:true, hints:nil)
    # endcapRect = NSMakeRect(bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height)
    # ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
  end

end
