class TabViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  PREVIEW_MODE          = 0
  SOURCE_MODE           = 1
  SPLIT_HORIZONTAL_MODE = 2
  SPLIT_VERTICAL_MODE   = 3

  attr_accessor :bookController, :textViewController, :webViewController
  attr_accessor :splitView, :splitViewSegementedControl, :renderImageView
  attr_accessor :viewMode

  def awakeFromNib
    view.delegate = self
    @splitView.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, 
        selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, 
        object:@textViewController.view.textStorage)
    @viewMode = PREVIEW_MODE
    hideTextView
    toggleCloseMenuKeyEquivalents
  end

  def textDidChange(notification)
    # required to update edited status
    view.needsDisplay = true
  end
  
  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    if item
      if item.imageable?
        @renderImageView.image = selectedTab.item.imageRep
        @textViewController.item = nil
        @webViewController.item = nil
      elsif item.flowable?
        @renderImageView.image = nil
        @textViewController.item = item
        @webViewController.item = point
        showWebView unless @viewMode == SOURCE_MODE
      else
        @renderImageView.image = nil
        @textViewController.item = item
        @webViewController.item = nil
        hideWebView
      end
    else
      @renderImageView.image = nil
      @textViewController.item = nil
      @webViewController.item = nil
    end
    updateToolbarItems
  end

  def numberOfTabs
    view.numberOfTabs
  end
  
  def addObject(object)
    if object.renderable?
      view.addObject(object)
      toggleCloseMenuKeyEquivalents
    end
  end

  def removeObject(object)
    view.removeObject(object)
  end

  def selectedTab
    view.selectedTab
  end

  def selectedItem
    view.selectedTab ? view.selectedTab.item : nil
  end

  def saveTab(sender)
    view.saveSelectedTab
  end

  def saveAllTabs(sender)
    view.editedTabs.each do |tab|
      view.saveTab(tab)
    end
  end

  def closeTab(sender)
    view.closeSelectedTab
    toggleCloseMenuKeyEquivalents
  end
  
  def selectedTabPrintView
    return nil unless selectedTab
    if @viewMode == SOURCE_MODE
      @textViewController.view
    else
      @webViewController.view.mainFrame.frameView.documentView
    end
  end

  def selectNextTab(sender)
    view.selectNextTab
  end

  def selectPreviousTab(sender)
    view.selectPreviousTab
  end

  def undoManagerForItem(item)
    view.tabForItem(item).undoManager
  end

  def toggleContentView(sender)
    case sender.selectedSegment
    when PREVIEW_MODE
      showWebView
      hideTextView
      @viewMode = PREVIEW_MODE
    when SOURCE_MODE
      showTextView
      hideWebView
      @viewMode = SOURCE_MODE
    when SPLIT_HORIZONTAL_MODE
      showWebView
      showTextView
      makeSplitViewOrientationHorizontal
      @viewMode = SPLIT_HORIZONTAL_MODE
    when SPLIT_VERTICAL_MODE
      showWebView
      showTextView
      makeSplitViewOrientationVertical
      @viewMode = SPLIT_VERTICAL_MODE
    else      
    end
  end

  def showWebView
    unless webViewVisible?
      @splitView.addSubview(@webViewController.view, positioned:NSWindowBelow, relativeTo:@textViewController.view.enclosingScrollView)
      updateSplitViewDividerPosition
    end
  end

  def showTextView
    unless textViewVisible?
      @splitView.addSubview(@textViewController.view.enclosingScrollView, positioned:NSWindowAbove, relativeTo:@webViewController.view)
      updateSplitViewDividerPosition
    end
  end

  def hideWebView
    if @splitView.subviews.size == 2
      @webViewController.view.removeFromSuperview
      @splitView.adjustSubviews
    end
  end

  def hideTextView
    if @splitView.subviews.size == 2
      @textViewController.view.enclosingScrollView.removeFromSuperview
      @splitView.adjustSubviews
    end
  end
  
  def makeSplitViewOrientationVertical
    if @splitView.vertical?
      @splitView.vertical = false
      updateSplitViewDividerPosition
    end
  end

  def makeSplitViewOrientationHorizontal
    unless @splitView.vertical?
      @splitView.vertical = true
      updateSplitViewDividerPosition
    end
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    proposedMin + SPLIT_VIEW_MINIMUM_POSITION
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    proposedMax - SPLIT_VIEW_MINIMUM_POSITION
  end

  def splitView(splitView, constrainSplitPosition:proposedPosition, ofSubviewAt:dividerIndex)
    @previousDividerPosition = proposedPosition 
  end
  
  def toggleCloseMenuKeyEquivalents
    fileMenu = NSApp.mainMenu.itemWithTitle("File")
    closeMenu = fileMenu.submenu.itemWithTitle("Close")
    closeTabMenu = fileMenu.submenu.itemWithTitle("Close Tab")
    if @bookController.window.isKeyWindow && view.numberOfTabs > 0
      closeTabMenu.keyEquivalent = "w"
      closeMenu.keyEquivalent = "W"
    else
      closeTabMenu.keyEquivalent = ""
      closeMenu.keyEquivalent = "w"
    end
  end
  
  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"selectNextTab:", :"selectPreviousTab:"
      view.numberOfTabs > 1
    when :"saveTab:", :"saveAllTabs:", :"closeTab:"
      view.numberOfTabs > 0
    when :"toggleSplitViewOrientation:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = @splitView.vertical? ? "Split Pane Horizontally" : "Split Pane Vertically"
      end
      view.numberOfTabs > 0
    when :"toggleContentView:"
      view.numberOfTabs > 0
    else
      true
    end
  end

  def updateToolbarItems
    @bookController.window.toolbar.visibleItems.each do |view|
      if view.isKindOfClass(NSToolbarItem)
        view.enabled = validateUserInterfaceItem(view)
      end
    end
  end

  private

  def webViewVisible?
    @splitView.subviews.size == 2 || @splitView.subviews[0] == @webViewController.view
  end

  def textViewVisible?
    @splitView.subviews.size == 2 || @splitView.subviews[0] == @textViewController.view.enclosingScrollView
  end
  
  def updateSplitViewDividerPosition
    return unless @splitView.subviews.size > 1
    maximum = @splitView.vertical? ? @splitView.bounds.size.width : @splitView.bounds.size.height
    if @previousDividerPosition.nil?
      @previousDividerPosition = maximum * 0.5
    elsif @previousDividerPosition > maximum
      @previousDividerPosition = maximum - SPLIT_VIEW_MINIMUM_POSITION
    elsif @previousDividerPosition < 0
      @previousDividerPosition = SPLIT_VIEW_MINIMUM_POSITION
    end
    @splitView.setPosition(@previousDividerPosition, ofDividerAtIndex:0)
    @splitView.adjustSubviews
  end
  
end