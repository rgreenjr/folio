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
    super
    # must draw entire documentVisibleRect since clipping area has been 
    # set and not all the background will update properly.
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
  
  def menuForEvent(event)
    if delegate
      window.makeFirstResponder(self)
      menuPoint = convertPoint(event.locationInWindow, fromView:nil)
      row = rowAtPoint(menuPoint)
      unless selectedRowIndexes.containsIndex(row)
        selectItem(itemAtRow(row))
      end
      delegate.menuForSelectedItems
    else
      super
    end
  end
  
  # def acceptsFirstResponder
  #   event = NSApp.currentEvent
  #   return true unless event
  #   row = rowAtPoint(convertPoint(event.locationInWindow, fromView:nil))
  #   isRowSelected(row) ? true : false
  # end

end
