class SectionRowView < NSTableRowView
  
  BACKGROUND = NSImage.imageNamed("SectionBackground.png")
  ENDCAP     = NSImage.imageNamed("SectionEndcap.png")
  
  def drawBackgroundInRect(rect)
    BACKGROUND.drawInRect(bounds, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0, respectFlipped:true, hints:nil)
    endcapRect = NSMakeRect(bounds.size.width - 2, bounds.origin.y, 2, bounds.size.height)
    ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0, respectFlipped:true, hints:nil)
  end

end
