class TabView < NSView

  DEFAULT_TAB_WIDTH = 350.0

  attr_accessor :tabCells, :selectedTabCell, :delegate

  def initWithFrame(frameRect)
    super
    @tabCells = []
    begColor  = NSColor.colorWithDeviceRed(0.921, green:0.921, blue:0.921, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.871, green:0.871, blue:0.871, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.820, green:0.820, blue:0.820, alpha:1.0)
    @gradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
    @lineColor = NSColor.colorWithDeviceRed(0.25, green:0.25, blue:0.25, alpha:1.0)
    
    # register trackingArea to receive mouseEntered and mouseExited events
    registerTrackingArea
    self
  end
  
  def drawRect(aRect)
    updateTabCellWidth
    @gradient.drawInRect(bounds, angle:270.0)
    @lineColor.set
    NSBezierPath.strokeLineFromPoint(CGPoint.new(bounds.origin.x, bounds.origin.y), toPoint:CGPoint.new(bounds.size.width, bounds.origin.y))
    @tabCells.each_with_index do |tabCell, index|
      tabCell.drawRect(rectForTabCellAtIndex(index))
    end
  end

  def isOpaque
    true
  end

  def numberOfTabs
    @tabCells.size
  end

  def selectedTab
    @selectedTabCell ? @selectedTabCell : nil
  end

  def selectNextTab
    return unless @selectedTabCell
    index = indexForTabCell(@selectedTabCell) + 1
    selectTabCell(@tabCells[index]) if index < numberOfTabs
  end

  def selectPreviousTab
    return unless @selectedTabCell
    index = indexForTabCell(@selectedTabCell) - 1
    selectTabCell(@tabCells[index]) if index >= 0
  end  

  def editedTabs
    @tabCells.select { |tabCell| tabCell.edited? }
  end

  def tabForItem(item)
    @tabCells.find { |tabCell| tabCell.item == item }
  end

  def addObject(object)
    return unless object
    if object.class == Point
      point = object
      item = point.item
    elsif object.class == ItemRef
      point = nil
      item = object.item
    else
      point = nil
      item = object
    end
    tabCell = tabForItem(item)
    unless tabCell
      tabCell = TabCell.new(item)
      @tabCells << tabCell
    end
    selectTabCell(tabCell, point)
  end

  def removeObject(object)
    return unless object
    if object.class == Point || object.class == ItemRef
      item = object.item
    else
      item = object
    end
    tabCell = tabForItem(item)
    closeTabCell(tabCell) if tabCell
  end  

  def saveSelectedTab
    if @selectedTabCell
      @selectedTabCell.save
      setNeedsDisplay(true)
    end
  end

  def saveTab(tabCell)
    tabCell.save
    setNeedsDisplay(true)
  end

  def closeSelectedTab
    saveOrCloseTabCell(@selectedTabCell) if @selectedTabCell
  end

  def closeAllTabs
    while @selectedTabCell
      closeTabCell(@selectedTabCell)
    end
  end

  def validateUserInterfaceItem(interfaceItem)
    numberOfTabs > 0
  end

  private

  def indexForTabCell(tab)
    @tabCells.each_with_index {|t, index| return index if tab == t}
    nil
  end

  def updateTabCellWidth
    if numberOfTabs * DEFAULT_TAB_WIDTH < bounds.size.width
      @tabCellWidth = DEFAULT_TAB_WIDTH
    else
      @tabCellWidth = (bounds.size.width / numberOfTabs).floor
    end
  end

  def rectForTabCell(tab)
    index = indexForTabCell(tab)
    NSMakeRect(bounds.origin.x + (index * @tabCellWidth), bounds.origin.y, @tabCellWidth, bounds.size.height)
  end

  def rectForTabCellAtIndex(index)
    NSMakeRect(bounds.origin.x + (index * @tabCellWidth), bounds.origin.y, @tabCellWidth, bounds.size.height)
  end
  
  def mouseEntered(event)
    point = convertPoint(event.locationInWindow, fromView:nil)
    tabCell = tabCellAtPoint(point)
    updateHoverTabCell(tabCell)
  end
  
  def mouseMoved(event)
    point = convertPoint(event.locationInWindow, fromView:nil)
    tabCell = tabCellAtPoint(point)
    updateHoverTabCell(tabCell)
  end

  def mouseExited(event)
    clearHoverTabCell
  end

  def mouseDown(event)
    point = convertPoint(event.locationInWindow, fromView:nil)
    @mouseDownTabCell = tabCellAtPoint(point)
    return unless @mouseDownTabCell
    if @mouseDownTabCell.closeButtonHit?(point, rectForTabCell(@mouseDownTabCell))
      @mouseDownTabCell.closeButtonPressed = true
      @mouseDownType = :close
    else
      @mouseDownType = :select
    end
    setNeedsDisplay(true)
  end

  def mouseDragged(event)
    return unless @mouseDownTabCell
    point = convertPoint(event.locationInWindow, fromView:nil)    
    if @mouseDownTabCell.closeButtonHit?(point, rectForTabCell(@mouseDownTabCell))
      @mouseDownTabCell.closeButtonPressed = true
    else
      @mouseDownTabCell.closeButtonPressed = false
    end
    setNeedsDisplay(true)
  end

  def mouseUp(event)
    return unless @mouseDownTabCell
    point = convertPoint(event.locationInWindow, fromView:nil)
    tabCell = tabCellAtPoint(point)
    if tabCell == @mouseDownTabCell
      if @mouseDownType == :close
        saveOrCloseTabCell(tabCell) if tabCell.closeButtonHit?(point, rectForTabCell(tabCell))
      else
        selectTabCell(tabCell)
      end
    end
    @mouseDownTabCell = nil
  end

  def updateTrackingAreas
    removeTrackingArea(trackingAreas.first)    
    registerTrackingArea
  end
  
  def tabCellAtPoint(point)
    index = (point.x / @tabCellWidth).floor
    index < numberOfTabs ? @tabCells[index] : nil
  end
  
  def selectTabCell(tabCell, point=nil)
    @selectedTabCell.selected = false if @selectedTabCell
    if tabCell
      tabCell.selected = true
      @selectedTabCell = tabCell
      item = tabCell.item
      point = point ? point : item      
    else
      item = nil
      @selectedTabCell = nil
    end
    @delegate.tabView(self, selectionDidChange:@selectedTabCell, item:item, point:point) if @delegate
    setNeedsDisplay true
    NSNotificationCenter.defaultCenter.postNotificationName("TabViewSelectionDidChange", object:self)
  end

  def saveOrCloseTabCell(tabCell)
    if tabCell.edited?
      showSaveAlert(tabCell)
    else
      closeTabCell(tabCell)
    end
  end

  def closeTabCell(tabCell)
    index = indexForTabCell(tabCell)
    @tabCells.delete_at(index)
    if @selectedTabCell == tabCell
      if @tabCells.empty?
        selectTabCell(nil)
      else
        index -= 1 if index >= numberOfTabs
        tabCell = @tabCells[index]
        selectTabCell(tabCell)
      end
    end
    setNeedsDisplay(true)
  end

  def showSaveAlert(tabCell)
    @saveTabCell = tabCell
    alert = NSAlert.alloc.init
    alert.messageText = "Do you want to save the changes you made to \"#{tabCell.item.name}\"?"
    alert.informativeText = "Your changes will be lost if you don't save them."
    alert.addButtonWithTitle "Save"
    alert.addButtonWithTitle "Cancel"
    alert.addButtonWithTitle "Don't Save"
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:"saveAlertDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def saveAlertDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      @saveTabCell.save
      closeTabCell(@saveTabCell)
    elsif code == NSAlertSecondButtonReturn
      @saveTabCell.closeButtonPressed = false
      setNeedsDisplay(true)
    elsif code == NSAlertThirdButtonReturn
      @saveTabCell.item.revert
      closeTabCell(@saveTabCell)
    end
  end
  
  def updateHoverTabCell(tabCell)
    clearHoverTabCell
    if tabCell
      @hoveringTabCell = tabCell
      @hoveringTabCell.hovering = true
      setNeedsDisplay(true)
    end
  end

  def clearHoverTabCell
    if @hoveringTabCell
      @hoveringTabCell.hovering = false
      @hoveringTabCell = nil
      setNeedsDisplay(true)
    end
  end

  def registerTrackingArea
    addTrackingArea(NSTrackingArea.alloc.initWithRect(self.bounds, 
      options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow), owner:self, userInfo:nil))
  end
  
end

