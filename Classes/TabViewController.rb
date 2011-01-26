class TabViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  PREVIEW_MODE          = 0
  SOURCE_MODE           = 1
  SPLIT_HORIZONTAL_MODE = 2
  SPLIT_VERTICAL_MODE   = 3

  VIEW_MODE_WEB  = 0
  VIEW_MODE_TEXT = 1
  VIEW_MODE_DUAL = 2

  attr_accessor :bookController, :textViewController, :webViewController
  attr_accessor :splitView, :splitViewSegementedControl, :renderImageView
  attr_accessor :viewMode

  def awakeFromNib
    @viewMode = VIEW_MODE_DUAL
    view.delegate = self
    @splitView.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, 
        selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, 
        object:@textViewController.view.textStorage)
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
        showWebView unless @viewMode == VIEW_MODE_TEXT
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

  def addObject(object)
    view.addObject(object) if object.renderable?
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
    when SOURCE_MODE
      showTextView
      hideWebView
    when SPLIT_HORIZONTAL_MODE
      showWebView
      showTextView
      makeSplitViewOrientationHorizontal
    when SPLIT_VERTICAL_MODE
      showWebView
      showTextView
      makeSplitViewOrientationVertical
    else      
    end
  end

  def showWebView
    unless webViewVisible?
      @splitView.addSubview(@webViewController.view, positioned:NSWindowBelow, relativeTo:@textViewController.view.enclosingScrollView)
      updateSplitViewDividerPosition
      @viewMode = VIEW_MODE_DUAL
    end
  end

  def showTextView
    unless textViewVisible?
      @splitView.addSubview(@textViewController.view.enclosingScrollView, positioned:NSWindowAbove, relativeTo:@webViewController.view)
      updateSplitViewDividerPosition
      @viewMode = VIEW_MODE_DUAL
    end
  end

  def hideWebView
    if @splitView.subviews.size == 2
      @webViewController.view.removeFromSuperview
      @splitView.adjustSubviews
      @viewMode = VIEW_MODE_TEXT
    end
  end

  def hideTextView
    if @splitView.subviews.size == 2
      @textViewController.view.enclosingScrollView.removeFromSuperview
      @splitView.adjustSubviews
      @viewMode = VIEW_MODE_WEB
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
