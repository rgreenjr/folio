class TabViewController < NSViewController

  attr_accessor :splitView, :textViewController, :webViewController

  def awakeFromNib
    view.delegate = self
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, object:@textViewController.view.textStorage)
  end

  def textDidChange(notification)
    # required to update edited status
    view.needsDisplay = true
  end
  
  def saveTab(sender)
    view.save(self)
  end
  
  def saveAllTabs(sender)
    view.editedTabs.each do |tab|
      view.saveTab(tab)
    end
  end

  def closeTab(sender)
    view.close(self)
  end

  def toggleSplitViewOrientation(sender)
    if sender.title == 'Split Views Horizontally'
      sender.title = 'Split Views Vertically'
      @splitView.vertical = false
    else
      sender.title = 'Split Views Horizontally'
      @splitView.vertical = true
    end
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
      view.size > 1
    else
      true
    end
  end

  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    @textViewController.item = item
    @webViewController.item = point
    # if item
    #   item.editable? ? addTextView : removeTextView
    # end
  end

  # def addTextView
  #   if @splitView.subviews.size == 1
  #     @splitView.setPosition(10.0, ofDividerAtIndex:0)
  #     # @splitView.addSubview(@textViewController.textView, positioned:NSWindowBelow, relativeTo:@splitView.subviews.first)
  #     @splitView.adjustSubviews
  #   end
  # end
  # 
  # def removeTextView
  #   if @splitView.subviews.size == 2
  #     # @splitView.subviews.last.removeFromSuperview
  #     @splitView.setPosition(100.0, ofDividerAtIndex:0)
  #     @splitView.adjustSubviews
  #   end
  # end

end
