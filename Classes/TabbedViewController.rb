class TabbedViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  LAYOUT_MODE_PREVIEW = 0
  LAYOUT_MODE_SOURCE  = 1
  LAYOUT_MODE_COMBO   = 2

  attr_accessor :bookController
  attr_accessor :sourceViewController
  attr_accessor :webViewController
  attr_accessor :tabContentPlaceholder
  attr_accessor :tabView
  attr_accessor :splitView
  attr_accessor :imageView
  
  def initWithBookController(bookController)
    initWithNibName("TabbedView", bundle:nil)
    @bookController = bookController
    @webViewPercentage = 0.5
    @sourceViewPercentage = 0.5
    self
  end

  def loadView
    super
    
    @sourceViewController.bookController = @bookController
    @webViewController.bookController = @bookController

    # add controllers to next responder chain
    @bookController.makeResponder(self)
    @bookController.makeResponder(@sourceViewController)
    @bookController.makeResponder(@webViewController)
    
    # put imageView in place
    @imageView.frame = @tabContentPlaceholder.frame
    @imageView.frameOrigin = NSZeroPoint
    @tabContentPlaceholder.addSubview(@imageView)
    
    # put splitView in place
    @splitView.frame = @tabContentPlaceholder.frame
    @splitView.frameOrigin = NSZeroPoint
    @tabContentPlaceholder.addSubview(@splitView)
    @splitView.hidden = true

    # register for source view text changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:('textDidChange:'), 
        name:NSTextStorageDidProcessEditingNotification, object:@sourceViewController.view.textStorage)
        
    # hide the source view initially
    hideSourceView
  end
  
  def show
    view.hidden = false
  end
  
  def hide
    view.hidden = true    
  end

  def textDidChange(notification)
    # required to update edited status
    @tabView.setNeedsDisplay(true)
  end
  
  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    if item
      if item.imageable?
        @imageView.image = selectedTab.item.imageRep
        @sourceViewController.item = nil
        @webViewController.item = nil
        @imageView.hidden = false
        @splitView.hidden = true
      elsif item.flowable?
        @imageView.image = nil
        @sourceViewController.item = item
        @webViewController.item = point
        @imageView.hidden = true
        @splitView.hidden = false
        showWebView unless layoutMode == LAYOUT_MODE_SOURCE
      else
        @imageView.image = nil
        @sourceViewController.item = item
        @webViewController.item = nil
        @imageView.hidden = true
        @splitView.hidden = false
        hideWebView
      end
    else
      @imageView.image = nil
      @sourceViewController.item = nil
      @webViewController.item = nil
      @imageView.hidden = true
      @splitView.hidden = true
    end
  end

  def numberOfTabs
    @tabView.numberOfTabs
  end
  
  def addObject(object)
    @tabView.addObject(object) if object.item.renderable?
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
  end
  
  def selectedTabPrintView
    return nil unless selectedTab
    if layoutMode == LAYOUT_MODE_SOURCE
      @sourceViewController.view
    else
      webView.mainFrame.frameView.documentView
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
      hideSourceView
      showWebView
    when LAYOUT_MODE_SOURCE
      hideWebView
      showSourceView
    when LAYOUT_MODE_COMBO
      showWebView
      showSourceView
    end
  end
  
  def showWebView
    unless splitViewContains?(webView)
      positionSplitViewSubviews
      @splitView.addSubview(webView, positioned:NSWindowBelow, relativeTo:sourceView)
      @bookController.layoutSegementedControl.selectSegmentWithTag(layoutMode)
    end
  end

  def hideWebView
    if splitViewContains?(webView)
      updateSubviewPercentages
      webView.removeFromSuperview
      @bookController.layoutSegementedControl.selectSegmentWithTag(layoutMode)
    end
  end

  def showSourceView
    unless splitViewContains?(sourceView)
      positionSplitViewSubviews
      @splitView.addSubview(sourceView, positioned:NSWindowAbove, relativeTo:webView)
      @bookController.layoutSegementedControl.selectSegmentWithTag(layoutMode)
    end
  end

  def hideSourceView
    if splitViewContains?(sourceView)
      updateSubviewPercentages
      sourceView.removeFromSuperview
      @bookController.layoutSegementedControl.selectSegmentWithTag(layoutMode)
    end
  end
  
  def toggleSplitOrientation(sender)
    updateSubviewPercentages
    @splitView.vertical = !@splitView.vertical?
    positionSplitViewSubviews
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    proposedMin + SPLIT_VIEW_MINIMUM_POSITION
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    proposedMax - SPLIT_VIEW_MINIMUM_POSITION
  end
  
  # def splitView(sender, shouldCollapseSubview:subview, forDoubleClickOnDividerAtIndex:index)
  #   puts "shouldCollapseSubview"
  #   @sourceViewPercentage = 0.5
  #   @sourceView = 0.5
  #   positionSplitViewSubviews
  #   false
  # end
  
  def layoutMode
    if splitViewContains?(webView) && splitViewContains?(sourceView)
      LAYOUT_MODE_COMBO
    elsif splitViewContains?(webView)
      LAYOUT_MODE_PREVIEW
    else
      LAYOUT_MODE_SOURCE
    end
  end
  
  def validateMenuItem(menuItem)
    case menuItem.action
    when :"selectNextTab:", :"selectPreviousTab:"
      numberOfTabs > 1
    when :"saveTab:", :"closeTab:"
      numberOfTabs > 0
    when :"toggleLayoutMode:"
      menuItem.state = stateForMenuItem(menuItem)
    when :"toggleSplitOrientation:"
      menuItem.title = @splitView.vertical? ? "Split Horizontally" : "Split Vertically"
      menuItem.enabled = numberOfTabs > 0 && layoutMode == LAYOUT_MODE_COMBO
    else
      true
    end
  end
  
  def validateToolbarItem(toolbarItem)
    case toolbarItem.action
    when :"reformatText:"
      numberOfTabs > 0 && selectedItem.flowable? && sourceViewController.visible?
    else
      true
    end
  end

  private

  def splitViewContains?(subview)
    @splitView.subviews.include?(subview)
  end
  
  def webView
    @webViewController.view
  end
  
  def sourceView
    @sourceViewController.view.enclosingScrollView
  end

  def updateSubviewPercentages
    if @splitView.subviews.size == 2
      @webViewPercentage = calculateSubviewPositionPercentage(webView)
      @sourceViewPercentage = 1.0 - @webViewPercentage
    end
  end
  
  def calculateSubviewPositionPercentage(subview)
    if @splitView.vertical?
      NSWidth(subview.bounds) / (NSWidth(@splitView.bounds) - @splitView.dividerThickness)
    else
      NSHeight(subview.bounds) / (NSHeight(@splitView.bounds) - @splitView.dividerThickness)
    end
  end
  
  def positionSplitViewSubviews
    positionSubview(webView, withPercentage:@webViewPercentage)
    positionSubview(sourceView, withPercentage:@sourceViewPercentage)
  end
  
  def positionSubview(subview, withPercentage:percentage)
    rect = @splitView.frame
    if @splitView.vertical?
      rect.size.width *= percentage
    else
      rect.size.height *= percentage
    end
    subview.frame = rect
  end
  
  def stateForMenuItem(menuItem)
    case menuItem.tag
    when LAYOUT_MODE_PREVIEW
      layoutMode == LAYOUT_MODE_PREVIEW ? NSOnState : NSOffState
    when LAYOUT_MODE_SOURCE
      layoutMode == LAYOUT_MODE_SOURCE ? NSOnState : NSOffState
    when LAYOUT_MODE_COMBO
      layoutMode == LAYOUT_MODE_COMBO ? NSOnState : NSOffState
    end
  end
  
  def makeResponder(controller)
    current = @bookController.window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
  end
  
end