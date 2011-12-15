class TabbedViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  LAYOUT_MODE_PREVIEW = 0
  LAYOUT_MODE_SOURCE  = 1
  LAYOUT_MODE_COMBO   = 2

  attr_accessor :bookController
  attr_accessor :textViewController
  attr_accessor :webViewController
  attr_accessor :tabContentPlaceholder
  attr_accessor :tabView
  attr_accessor :splitView
  attr_accessor :imageView
  
  def initWithBookController(bookController)
    initWithNibName("TabbedView", bundle:nil)
    @bookController = bookController
    self
  end

  def loadView
    super
    
    @textViewController.bookController = @bookController
    @webViewController.bookController = @bookController

    # add controllers to next responder chain
    @bookController.makeResponder(self)
    @bookController.makeResponder(@textViewController)
    @bookController.makeResponder(@webViewController)
    
    # put imageView in place
    @imageView.frame = @tabContentPlaceholder.frame
    @imageView.frameOrigin = NSZeroPoint
    @tabContentPlaceholder.addSubview(@imageView)
    
    # put splitView in place
    @splitView.frame = @tabContentPlaceholder.frame
    @splitView.frameOrigin = NSZeroPoint
    @tabContentPlaceholder.addSubview(@splitView)

    # register for source view text changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, object:@textViewController.view.textStorage)
        
    # default to preview layout mode
    @layoutMode = LAYOUT_MODE_PREVIEW
    
    # hide the source view initially
    hideTextView
    
    # update close menu shortcuts
    toggleCloseMenuKeyEquivalents
    
    # update toolbar state
    updateToolbarItems
  end
  
  def show
    view.hidden = false
  end
  
  def hide
    view.hidden = true    
  end

  def textDidChange(notification)
    # required to update edited status
    @tabView.needsDisplay = true
  end
  
  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    if item
      if item.imageable?
        @imageView.image = selectedTab.item.imageRep
        @textViewController.item = nil
        @webViewController.item = nil
        @imageView.hidden = false
        @splitView.hidden = true
      elsif item.flowable?
        @imageView.image = nil
        @textViewController.item = item
        @webViewController.item = point
        @imageView.hidden = true
        @splitView.hidden = false
        showWebView unless @layoutMode == LAYOUT_MODE_SOURCE
      else
        @imageView.image = nil
        @textViewController.item = item
        @webViewController.item = nil
        @imageView.hidden = true
        @splitView.hidden = false
        hideWebView
      end
    else
      @imageView.image = nil
      @textViewController.item = nil
      @webViewController.item = nil
      @imageView.hidden = true
      @splitView.hidden = true
    end
    updateToolbarItems
  end

  def numberOfTabs
    @tabView.numberOfTabs
  end
  
  def addObject(object)
    if object.item.renderable?
      @tabView.addObject(object)
      toggleCloseMenuKeyEquivalents
    end
  end

  def removeObject(object)
    @tabView.removeObject(object)
  end

  def selectedTab
    @tabView.selectedTab
  end

  def selectedItem
    @tabView.selectedTab ? @tabView.selectedTab.item : nil
  end

  def saveTab(sender)
    @tabView.saveSelectedTab
  end

  def saveAllTabs(sender)
    @tabView.editedTabs.each do |tab|
      @tabView.saveTab(tab)
    end
  end

  def closeTab(sender)
    @tabView.closeSelectedTab
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
    @tabView.selectNextTab
  end

  def selectPreviousTab(sender)
    @tabView.selectPreviousTab
  end

  def undoManagerForItem(item)
    @tabView.tabForItem(item).undoManager
  end

  def toggleLayoutMode(sender)
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
    @bookController.layoutSegementedControl.selectSegmentWithTag(@layoutMode)
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
    if @bookController.window.isKeyWindow && numberOfTabs > 0
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
      numberOfTabs > 1
    when :"saveTab:", :"closeTab:"
      numberOfTabs > 0
    when :"toggleLayoutMode:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.state = stateForMenuItem(interfaceItem)
      end
      numberOfTabs > 0
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
    numberOfTabs > 0 && @layoutMode == LAYOUT_MODE_COMBO  
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
  
  def makeResponder(controller)
    current = @bookController.window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
  end

end