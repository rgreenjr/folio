class TabViewController < NSViewController

  HORIZONTAL_ORIENTATION_TAG = 0
  VERTICAL_ORIENTATION_TAG   = 1
  SPLIT_VIEW_MINIMUM_HEIGHT  = 50

  attr_accessor :splitView, :textViewController, :webViewController, :bookController
  attr_accessor :splitViewSegementedControl, :renderImageView

  def awakeFromNib
    view.delegate = self
    @splitView.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('textDidChange:'),
    name:NSTextStorageDidProcessEditingNotification, object:@textViewController.view.textStorage)
  end

  def textDidChange(notification)
    # required to update edited status
    view.needsDisplay = true
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

  def undoManagerForItem(item)
    view.tabForItem(item).undoManager
  end

  def toggleSplitViewOrientation(sender)
    if sender == @splitViewSegementedControl
      @splitViewSegementedControl.selectedSegment == HORIZONTAL_ORIENTATION_TAG ? makeSplitViewOrientationVertical : makeSplitViewOrientationHorizontal
    else
      @splitViewSegementedControl.selectedSegment == HORIZONTAL_ORIENTATION_TAG ? makeSplitViewOrientationHorizontal : makeSplitViewOrientationVertical
    end
  end

  def toggleWebView(sender)
    @splitView.subviews.size == 2 ? hideWebView : showWebView
  end

  def toggleTextView(sender)
    @splitView.subviews.size == 2 ? hideTextView : showTextView
  end

  def showWebView
    if @splitView.subviews.size == 1 && @splitView.subviews[0] != @webViewController.view
      @splitView.addSubview(@webViewController.view, positioned:NSWindowBelow, relativeTo:@textViewController.view.enclosingScrollView)
      @splitView.setPosition(calculatePreviousSplitViewPosition, ofDividerAtIndex:0)
      @splitView.adjustSubviews
    end
  end

  def showTextView
    if @splitView.subviews.size == 1 && @splitView.subviews[0] != @textViewController.view.enclosingScrollView
      @splitView.addSubview(@textViewController.view.enclosingScrollView, positioned:NSWindowAbove, relativeTo:@webViewController.view)
      @splitView.setPosition(calculatePreviousSplitViewPosition, ofDividerAtIndex:0)
      @splitView.adjustSubviews
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

  def selectNextTab(sender)
    view.selectNextTab
  end

  def selectPreviousTab(sender)
    view.selectPreviousTab
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"selectNextTab:", :"selectPreviousTab:"
      view.numberOfTabs > 1
    when :"saveTab:", :"saveAllTabs:", :"closeTab:"
      view.numberOfTabs > 0
    else
      true
    end
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
        showWebView
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
  end

  def makeSplitViewOrientationVertical
    @splitViewSegementedControl.selectSegmentWithTag(HORIZONTAL_ORIENTATION_TAG)
    @splitView.vertical = false
    @splitView.adjustSubviews
  end

  def makeSplitViewOrientationHorizontal
    @splitViewSegementedControl.selectSegmentWithTag(VERTICAL_ORIENTATION_TAG)
    @splitView.vertical = true
    @splitView.adjustSubviews
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    proposedMin + SPLIT_VIEW_MINIMUM_HEIGHT
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    proposedMax - SPLIT_VIEW_MINIMUM_HEIGHT
  end

  def splitView(splitView, constrainSplitPosition:proposedPosition, ofSubviewAt:dividerIndex)
    @previousSplitViewPosition = proposedPosition 
  end
  
  def calculatePreviousSplitViewPosition
    height = @splitView.bounds.size.height
    if @previousSplitViewPosition.nil?
      @previousSplitViewPosition = height * 0.5
    elsif @previousSplitViewPosition > height
      @previousSplitViewPosition = height - SPLIT_VIEW_MINIMUM_HEIGHT
    elsif @previousSplitViewPosition < 0
      @previousSplitViewPosition = SPLIT_VIEW_MINIMUM_HEIGHT
    end
    @previousSplitViewPosition
  end

end
