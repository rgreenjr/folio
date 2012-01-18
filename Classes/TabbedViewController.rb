class TabbedViewController < NSViewController

  SPLIT_VIEW_MINIMUM_POSITION  = 50
  
  LAYOUT_MODE_PREVIEW    = 0
  LAYOUT_MODE_SOURCE     = 1
  LAYOUT_MODE_HORIZONTAL = 2
  LAYOUT_MODE_VERTICAL   = 3

  attr_reader   :bookController
  attr_reader   :layoutMode
  attr_accessor :sourceViewController
  attr_accessor :webViewController
  attr_accessor :tabContentPlaceholder
  attr_accessor :tabView
  attr_accessor :splitView
  attr_accessor :imageView
  
  def initWithBookController(controller)
    initWithNibName("TabbedView", bundle:nil)
    @bookController = controller
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
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"textDidChange:", 
        name:NSTextStorageDidProcessEditingNotification, object:@sourceViewController.view.textStorage)

    # set layoutMode to preview
    self.layoutMode = LAYOUT_MODE_VERTICAL
  end
  
  def show
    view.hidden = false
  end
  
  def hide
    view.hidden = true    
  end

  def textDidChange(notification)
    @tabView.setNeedsDisplay(true) # required to toggle close icon to edited state
  end
  
  def tabView(tabView, selectionDidChange:selectedTab, item:item, point:point)
    if item
      if item.imageable?
        @imageView.image = item.imageRep
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
        if sourceLayoutMode?
          hideWebView
          showSourceView
        elsif previewLayoutMode?
          showWebView
          hideSourceView
        else
          showWebView
          showSourceView
        end
      else
        @imageView.image = nil
        @sourceViewController.item = item
        @webViewController.item = nil
        @imageView.hidden = true
        @splitView.hidden = false
        showSourceView
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
    if sourceLayoutMode?
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
    mode = (sender.class == NSMenuItem) ? sender.tag : sender.selectedSegment
    self.layoutMode = mode
  end
  
  def layoutMode=(mode)
    @layoutMode = mode
    case @layoutMode
    when LAYOUT_MODE_PREVIEW
      hideSourceView
      showWebView
    when LAYOUT_MODE_SOURCE
      hideWebView
      showSourceView
    when LAYOUT_MODE_HORIZONTAL
      showWebView
      showSourceView
      toggleSplitOrientation(self) if @splitView.vertical?
    when LAYOUT_MODE_VERTICAL
      showWebView
      showSourceView
      toggleSplitOrientation(self) unless @splitView.vertical?
    end
    @bookController.layoutSegementedControl.selectSegmentWithTag(@layoutMode)
  end
  
  def ensureSourceViewVisible
    return unless previewLayoutMode?
    self.layoutMode = @splitView.vertical? ? LAYOUT_MODE_VERTICAL : LAYOUT_MODE_HORIZONTAL
  end
  
  def previewLayoutMode?
    @layoutMode == LAYOUT_MODE_PREVIEW
  end
  
  def sourceLayoutMode?
    @layoutMode == LAYOUT_MODE_SOURCE
  end
  
  def horizontalLayoutMode?
    @layoutMode == LAYOUT_MODE_HORIZONTAL
  end
  
  def verticalLayoutMode?
    @layoutMode == LAYOUT_MODE_VERTICAL
  end
  
  def showWebView
    unless splitViewContains?(webView)
      restoreSplitviewPosition
      @splitView.addSubview(webView, positioned:NSWindowBelow, relativeTo:sourceView)
    end
  end

  def hideWebView
    if splitViewContains?(webView)
      storeSplitviewPosition
      webView.removeFromSuperview
    end
  end

  def showSourceView
    unless splitViewContains?(sourceView)
      restoreSplitviewPosition
      @splitView.addSubview(sourceView, positioned:NSWindowAbove, relativeTo:webView)
    end
  end

  def hideSourceView
    if splitViewContains?(sourceView)
      storeSplitviewPosition
      sourceView.removeFromSuperview
    end
  end
  
  def toggleSplitOrientation(sender)
    @splitView.vertical = !@splitView.vertical?
    restoreSplitviewPosition
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    proposedMin + SPLIT_VIEW_MINIMUM_POSITION
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    proposedMax - SPLIT_VIEW_MINIMUM_POSITION
  end
  
  def splitViewDidResizeSubviews(notification)
    storeSplitviewPosition
  end
  
  def validateMenuItem(menuItem)
    case menuItem.action
    when :"selectNextTab:", :"selectPreviousTab:"
      numberOfTabs > 1
    when :"saveTab:", :"closeTab:"
      numberOfTabs > 0
    when :"toggleLayoutMode:"
      menuItem.state = stateForMenuItem(menuItem)
      true
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

  def storeSplitviewPosition
    if @splitView.subviews.size == 2
      @webViewSplitviewPercentage = calculateSubviewPositionPercentage(webView)
      @sourceViewSplitviewPercentage = 1.0 - @webViewSplitviewPercentage
    end
  end
  
  def calculateSubviewPositionPercentage(subview)
    if @splitView.vertical?      
      NSWidth(subview.bounds) / (NSWidth(@splitView.bounds) - @splitView.dividerThickness)
    else
      NSHeight(subview.bounds) / (NSHeight(@splitView.bounds) - @splitView.dividerThickness)
    end
  end
  
  def restoreSplitviewPosition
    if @webViewSplitviewPercentage.nil? || @sourceViewSplitviewPercentage.nil?
      @webViewSplitviewPercentage = 0.5
      @sourceViewSplitviewPercentage = 0.5
    end
    positionSubview(webView, withPercentage:@webViewSplitviewPercentage)
    positionSubview(sourceView, withPercentage:@sourceViewSplitviewPercentage)
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
      previewLayoutMode? ? NSOnState : NSOffState
    when LAYOUT_MODE_SOURCE
      sourceLayoutMode? ? NSOnState : NSOffState
    when LAYOUT_MODE_HORIZONTAL
      horizontalLayoutMode? ? NSOnState : NSOffState
    when LAYOUT_MODE_VERTICAL
      verticalLayoutMode? ? NSOnState : NSOffState
    end
  end
  
  def makeResponder(controller)
    current = @bookController.window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
  end
  
end