class TabView < NSView
  
  DEFAULT_TAB_WIDTH = 350.0
  
  attr_accessor :tabs, :selectedTab, :textViewController, :webViewController
  
  def initWithFrame(frameRect)
    @tabs = []
    begColor  = NSColor.colorWithDeviceRed(0.921, green:0.921, blue:0.921, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.871, green:0.871, blue:0.871, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.820, green:0.820, blue:0.820, alpha:1.0)
    @gradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
    super
  end
  
  def tabForItem(item)
    @tabs.each_with_index {|tab, index| return tab if tab.item == item}
    nil
  end
  
  def indexForTab(tab)
    @tabs.each_with_index {|t, index| return index if tab == t}
    nil
  end
  
  def add(object)
    return unless object
    if object.is_a?(Point)
      point = object
      item = object.item
    else
      point = nil
      item = object
    end
    tab = tabForItem(item)
    unless tab
      tab = Tab.new(item)
      @tabs << tab
    end
    selectTab(tab, point)
  end
  
  def drawRect(aRect)
    # puts "TabView drawRect = #{NSStringFromRect(aRect)}"
    updateTabWidth
    drawBackground
    @tabs.each_with_index do |tab, index|
      tab.drawRect(rectForTabAtIndex(index))
    end
  end
  
  def updateTabWidth
    if @tabs.size * DEFAULT_TAB_WIDTH < bounds.size.width
      @tabWidth = DEFAULT_TAB_WIDTH
    else
      @tabWidth = (bounds.size.width / @tabs.size).floor
    end
  end
  
  def drawBackground
    rect = NSMakeRect(bounds.origin.x + (@tabs.size * @tabWidth), bounds.origin.y, bounds.size.width, bounds.size.height)
    @gradient.drawInRect(rect, angle:270.0)
  end

  def rectForTabAtIndex(index)
    NSMakeRect(bounds.origin.x + (index * @tabWidth), bounds.origin.y, @tabWidth, bounds.size.height)
  end
  
  def mouseDown(event)
    tab = tabAtPoint(convertPoint(event.locationInWindow, fromView:nil))
    return unless tab
    if event.clickCount == 1
      selectTab(tab)
    else
      if @selectedTab.dirty?
        showSaveAlert(@selectedTab)
      else
        closeTab(tab)
      end
    end
  end
  
  def tabAtPoint(point)
    index = (point.x / @tabWidth).floor
    index < @tabs.size ? @tabs[index] : nil
  end

  def selectTab(tab, point=nil)
    @selectedTab.selected = false if @selectedTab
    tab.selected = true
    @selectedTab = tab
    self.needsDisplay = true
    @textViewController.item = tab.item
    if point
      @webViewController.item = point
    else
      @webViewController.item = tab.item
    end
  end

  def closeTab(tab)
    return unless @selectedTab == tab
    index = indexForTab(tab)
    @tabs.delete_at(index)
    self.needsDisplay = true
    if @tabs.empty?
      @selectedTab = nil
    else
      tab = @tabs[0]
      selectTab(tab)
    end
  end

  def showSaveAlert(tab)
    puts "@selectedTab = #{@selectedTab}"
    alert = NSAlert.alloc.init
    alert.messageText = "Do you want to save the changes you made to \"#{tab.item.name}\"?"
    alert.informativeText = "Your changes will be lost if you don't save them."
    alert.addButtonWithTitle "Save"
    alert.addButtonWithTitle "Cancel"
    alert.addButtonWithTitle "Don't Save"
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:"saveAlertDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end
  
  def saveAlertDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      @selectedTab.item.save
      closeTab(@selectedTab)
    elsif code == NSAlertThirdButtonReturn
      @selectedTab.item.revert
      closeTab(@selectedTab)
    end
  end
  
end