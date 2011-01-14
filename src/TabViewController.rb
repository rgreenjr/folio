class TabViewController < NSViewController

  HORIZONTAL_ORIENTATION_TAG = 0
  VERTICAL_ORIENTATION_TAG   = 1

  attr_accessor :splitView, :textViewController, :webViewController, :bookController
  attr_accessor :splitViewSegementedControl, :renderImageView

  def awakeFromNib
    view.delegate = self
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

  def selectNextTab(sender)
    view.selectNextTab
  end

  def selectPreviousTab(sender)
    view.selectPreviousTab
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.title
    when 'Select Next Tab', 'Select Previous Tab'
      view.numberOfTabs > 1
    when 'Close Tab', 'Save Tab', 'Save All Tabs'
      view.numberOfTabs > 0
    else
      true
    end
  end

  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    return unless item
    if item.imageable?
      @renderImageView.image = selectedTab.item.imageRep
    else
      @textViewController.item = item
      @webViewController.item = point
    end
  end

end
