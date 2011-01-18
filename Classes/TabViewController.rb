class TabViewController < NSViewController

  HORIZONTAL_ORIENTATION_TAG = 0
  VERTICAL_ORIENTATION_TAG   = 1
  SPLIT_VIEW_MINIMUM_POSITION  = 50

  attr_accessor :bookController, :textViewController, :webViewController
  attr_accessor :splitView, :splitViewSegementedControl, :renderImageView

  def awakeFromNib
    view.delegate = self
    @splitView.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('textDidChange:'), name:NSTextStorageDidProcessEditingNotification, object:@textViewController.view.textStorage)
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
    elsif @splitView.subviews[0] == @webViewController.view
      showTextView
      hideWebView
    end
  end

  def showWebViewOnly(sender)
    if @splitView.subviews.size == 2
      hideTextView
    elsif @splitView.subviews[0] == @textViewController.view.enclosingScrollView
      showWebView
      hideTextView
    end
  end
  
  def showTextAndWebViews(sender)
    if @splitView.subviews.size == 1
      if @splitView.subviews[0] == @webViewController.view
        showTextView
      else
        showWebView
      end
    end
  end

  # def toggleWebView(sender)
  #   @splitView.subviews.size == 2 ? hideWebView : showWebView
  # end
  # 
  # def toggleTextView(sender)
  #   @splitView.subviews.size == 2 ? hideTextView : showTextView
  # end

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
  
  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"selectNextTab:", :"selectPreviousTab:"
      view.numberOfTabs > 1
    when :"saveTab:", :"saveAllTabs:", :"closeTab:"
      view.numberOfTabs > 0
    when :"toggleWebView"
      @splitView.subviews.size == 2 || @splitView.subviews[0] != @webViewController.view
    when :"toggleTextView"
      @splitView.subviews.size == 2 || @splitView.subviews[0] != @textViewController.enclosingScrollView
    else
      true
    end
  end

  private
  
  def updateSplitViewDividerPosition
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
