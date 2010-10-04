class TabView < NSView

  DEFAULT_TAB_WIDTH = 350.0

  attr_accessor :tabs, :selectedTab, :textViewController, :webViewController

  def awakeFromNib
    ctr = NSNotificationCenter.defaultCenter
    ctr.addObserver(self, selector:('textDidChange:'), name:NSTextStorageDidProcessEditingNotification, object:@textViewController.textView.textStorage)
  end

  def initWithFrame(frameRect)
    super
    @tabs = []
    begColor  = NSColor.colorWithDeviceRed(0.921, green:0.921, blue:0.921, alpha:1.0)
    midColor  = NSColor.colorWithDeviceRed(0.871, green:0.871, blue:0.871, alpha:1.0)
    endColor  = NSColor.colorWithDeviceRed(0.820, green:0.820, blue:0.820, alpha:1.0)
    @gradient = NSGradient.alloc.initWithColors([begColor, midColor, endColor], [0.0, 0.5, 1.0], colorSpace:NSColorSpace.genericRGBColorSpace)
    self
  end

  def acceptsFirstResponder
    true
  end

  def textDidChange(notification)
    setNeedsDisplay true
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
      item = point.item
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

  def rectForTab(tab)
    index = indexForTab(tab)
    NSMakeRect(bounds.origin.x + (index * @tabWidth), bounds.origin.y, @tabWidth, bounds.size.height)
  end

  def rectForTabAtIndex(index)
    NSMakeRect(bounds.origin.x + (index * @tabWidth), bounds.origin.y, @tabWidth, bounds.size.height)
  end

  def mouseDown(event)
    point = convertPoint(event.locationInWindow, fromView:nil)
    tab = tabAtPoint(point)
    return unless tab
    if event.clickCount == 1
      if tab.closeButtonHit?(point, rectForTab(tab))
        tab.closeButtonPressed = true
      end
      @clickedTab = tab
      setNeedsDisplay true
    end
  end

  def mouseDragged(event)
    return unless @clickedTab
    point = convertPoint(event.locationInWindow, fromView:nil)    
    if @clickedTab.closeButtonHit?(point, rectForTab(@clickedTab))
       @clickedTab.closeButtonPressed = true
    else
       @clickedTab.closeButtonPressed = false
    end
    setNeedsDisplay true
  end

  def mouseUp(event)
    point = convertPoint(event.locationInWindow, fromView:nil)
    tab = tabAtPoint(point)
    if tab && tab == @clickedTab
      puts "tab is clicked tab"
      if tab.closeButtonHit?(point, rectForTab(tab))
        puts "closing"
        if tab.item.edited?
          showSaveAlert(@selectedTab)
        else
          closeTab(tab)
        end
      else
        puts "selecting"
        selectTab(tab)
      end
    end
    @clickedTab = nil
  end

  def tabAtPoint(point)
    index = (point.x / @tabWidth).floor
    index < @tabs.size ? @tabs[index] : nil
  end

  def selectTab(tab, point=nil)
    @selectedTab.selected = false if @selectedTab
    tab.selected = true
    @selectedTab = tab
    setNeedsDisplay true
    @textViewController.item = tab.item
    if point
      @webViewController.item = point
    else
      @webViewController.item = tab.item
    end
  end

  def closeTab(tab)
    index = indexForTab(tab)
    @tabs.delete_at(index)
    if @selectedTab == tab
      if @tabs.empty?
        @selectedTab = nil
      else
        index -= 1 if index >= @tabs.size
        tab = @tabs[index]
        selectTab(tab)
      end
    end
    setNeedsDisplay true
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