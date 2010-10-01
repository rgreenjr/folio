class TabView < NSView
  
  DEFAULT_TAB_WIDTH = 150.0
  
  attr_accessor :tabs, :selectedTab
  attr_accessor :tabs, :textViewController, :webViewController
  
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
  
  def addItem(item)
    return unless item
    point = nil
    if item.is_a?(Point)
      point = item
      item = point.item
    end
    tab = tabForItem(item)
    unless tab
      tab = Tab.new(item)
      @tabs << tab
    end
    self.selectTab(tab, point)
  end
  
  def addPoint(point)
    # 
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
    puts "event.clickCount = #{event.clickCount}"
    tab = tabAtPoint(convertPoint(event.locationInWindow, fromView:nil))
    if tab
      if event.clickCount == 1
        self.selectTab(tab)
      else
        unselectTab(tab)
      end
    end
  end
  
  def tabAtPoint(point)
    index = (point.x / @tabWidth).floor
    puts "index = #{index}"
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

  def unselectTab(tab)
    return unless @selectedTab == tab
    index = indexForTab(tab)
    @tabs.delete_at(index)
    self.needsDisplay = true
    if @tabs.empty?
      @selectedTab = nil
    else
      tab = @tabs[0]
      tab.selected = true
      @selectedTab = tab
      @textViewController.item = tab.item
      @webViewController.item = tab.item
    end
  end

end