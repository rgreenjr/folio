class TabViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  LAYOUT_MODE_PREVIEW = 0
  LAYOUT_MODE_SOURCE  = 1
  LAYOUT_MODE_COMBO   = 2

  attr_accessor :bookController, :textViewController, :webViewController
  attr_accessor :splitView, :layoutSegementedControl, :renderImageView
  attr_accessor :layoutMode

  def awakeFromNib
    view.delegate = self
    @splitView.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, 
        selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, 
        object:@textViewController.view.textStorage)
    @layoutMode = LAYOUT_MODE_PREVIEW
    hideTextView
    toggleCloseMenuKeyEquivalents
    updateToolbarItems
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
        showWebView unless @layoutMode == LAYOUT_MODE_SOURCE
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
    if object.item.renderable?
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
    if @layoutMode == LAYOUT_MODE_SOURCE
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
    tag = sender.class == NSMenuItem ? sender.tag : sender.selectedSegment
    case tag
    when LAYOUT_MODE_PREVIEW
      showWebView
      hideTextView
      @layoutMode = LAYOUT_MODE_PREVIEW
    when LAYOUT_MODE_SOURCE
      showTextView
      hideWebView
      @layoutMode = LAYOUT_MODE_SOURCE
    when LAYOUT_MODE_COMBO
      showWebView
      showTextView
      @layoutMode = LAYOUT_MODE_COMBO
    end
    
    # set toolbar segmented control to new layout
    @layoutSegementedControl.selectSegmentWithTag(@layoutMode)
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
  
  def toggleSplitOrientation(sender)
    if @splitView.vertical?
      makeSplitViewOrientationHorizontal
    else
      makeSplitViewOrientationVertical
    end
  end
  
  def makeSplitViewOrientationVertical
    unless @splitView.vertical?
      @splitView.vertical = true
      updateSplitViewDividerPosition
    end
  end

  def makeSplitViewOrientationHorizontal
    if @splitView.vertical?
      @splitView.vertical = false
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
    when :"saveTab:", :"closeTab:"
      view.numberOfTabs > 0
    when :"toggleContentView:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.state = stateForMenuItem(interfaceItem)
      end
      view.numberOfTabs > 0
    when :"toggleSplitOrientation:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = @splitView.vertical? ? "Split Horizontally" : "Split Vertically"
      end
      interfaceItem.enabled = enableSplitOrientationInterfaceItem?
    else
      true
    end
  end

  def updateToolbarItems
    @bookController.window.toolbar.visibleItems.each do |view|
      if view.class == NSToolbarItem
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
  
  def stateForMenuItem(menuItem)
    case menuItem.tag
    when LAYOUT_MODE_PREVIEW
      @layoutMode == LAYOUT_MODE_PREVIEW ? NSOnState : NSOffState
    when LAYOUT_MODE_SOURCE
      @layoutMode == LAYOUT_MODE_SOURCE ? NSOnState : NSOffState
    when LAYOUT_MODE_COMBO
      @layoutMode == LAYOUT_MODE_COMBO ? NSOnState : NSOffState
    end
  end
  
  def enableSplitOrientationInterfaceItem?
    view.numberOfTabs > 0 && @layoutMode == LAYOUT_MODE_COMBO  
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