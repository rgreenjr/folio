class TabViewController < NSViewController

  HORIZONTAL_ORIENTATION_TAG   = 0
  VERTICAL_ORIENTATION_TAG     = 1
  SPLIT_VIEW_MINIMUM_POSITION  = 50

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
    view.addObject(object)
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

  def showTextViewOnly(sender)
    if @splitView.subviews.size == 2
      hideWebView
      @viewMode = VIEW_MODE_TEXT
    elsif @splitView.subviews[0] == @webViewController.view
      showTextView
      hideWebView
      @viewMode = VIEW_MODE_TEXT
    end
  end

  def showWebViewOnly(sender)
    if @splitView.subviews.size == 2
      hideTextView
      @viewMode = VIEW_MODE_WEB
    elsif @splitView.subviews[0] == @textViewController.view.enclosingScrollView
      showWebView
      hideTextView
      @viewMode = VIEW_MODE_WEB
    end
  end

  def showTextAndWebViews(sender)
    if @splitView.subviews.size == 1
      if @splitView.subviews[0] == @webViewController.view
        showTextView
      else
        showWebView
      end
      @viewMode = VIEW_MODE_DUAL
    end
  end

  def showWebView
    if @splitView.subviews.size == 1 && @splitView.subviews[0] != @webViewController.view
      @splitView.addSubview(@webViewController.view, positioned:NSWindowBelow, relativeTo:@textViewController.view.enclosingScrollView)
      updateSplitViewDividerPosition
    end
  end

  def showTextView
    if @splitView.subviews.size == 1 && @splitView.subviews[0] != @textViewController.view.enclosingScrollView
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

  def toggleSplitViewOrientation(sender)
    if sender == @splitViewSegementedControl
      @splitViewSegementedControl.selectedSegment == HORIZONTAL_ORIENTATION_TAG ? makeSplitViewOrientationVertical : makeSplitViewOrientationHorizontal
    else
      @splitViewSegementedControl.selectedSegment == HORIZONTAL_ORIENTATION_TAG ? makeSplitViewOrientationHorizontal : makeSplitViewOrientationVertical
    end
  end

  def makeSplitViewOrientationVertical
    @splitViewSegementedControl.selectSegmentWithTag(HORIZONTAL_ORIENTATION_TAG)
    @splitView.vertical = false
    updateSplitViewDividerPosition
  end

  def makeSplitViewOrientationHorizontal
    @splitViewSegementedControl.selectSegmentWithTag(VERTICAL_ORIENTATION_TAG)
    @splitView.vertical = true
    updateSplitViewDividerPosition
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
    when :"showTextAndWebViews:"
      view.numberOfTabs > 0 && @splitView.subviews.size != 2
    when :"showWebViewOnly:", :"toggleWebView"
      view.numberOfTabs > 0 && (@splitView.subviews.size == 2 || @splitView.subviews[0] != @webViewController.view)
    when :"showTextViewOnly:", :"toggleTextView"
      view.numberOfTabs > 0 && (@splitView.subviews.size == 2 || @splitView.subviews[0] != @textViewController.view.enclosingScrollView)
    when :"toggleSplitViewOrientation:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = @splitView.vertical? ? "Split Horizontally" : "Split Vertically"
      end
      view.numberOfTabs > 0
    when :"makeSplitViewOrientationHorizontal:", :"makeSplitViewOrientationVertical:"
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
