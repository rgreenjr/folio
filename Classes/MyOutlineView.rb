class MyOutlineView < NSOutlineView
  
  BLUE_TEXTURE_COLOR  = NSColor.colorWithPatternImage(NSImage.imageNamed("BlueTexture.png"))
  BLUE_TEXTURE_ENDCAP = NSImage.imageNamed("BlueTextureEndcap.png")
  
  def awakeFromNib
  	enclosingScrollView.drawsBackground = false
  end

  def drawBackgroundImage
		rect = enclosingScrollView.documentVisibleRect		
		BLUE_TEXTURE_COLOR.set
    NSRectFill(rect)
    endcapRect = NSMakeRect(rect.size.width - 2, rect.origin.y, 2, rect.size.height)
    BLUE_TEXTURE_ENDCAP.drawInRect(endcapRect, fromRect:NSZeroRect, operation:NSCompositeCopy, fraction:1.0)
  end

  def drawBackgroundInClipRect(clipRect)
    # drawing our background image in this method does not work all by itself,
    # because the clipping area has been set and not ALL the background
    # will update properly.  You also need to implement "drawRect" as well
    super
  	drawBackgroundImage
  end

  def drawRect(drawRect)
  	super
  	drawBackgroundImage
  end

  def expandItem(item, expandChildren:expandChildren)
    super
    needsDisplay = true
  end

  def collapseItem(item, collapseChildren:collapseChildren)
    super
    needsDisplay = true
  end
  
end
