class WindowController < NSWindowController

  MINIMUM_WIDTH = 150.0

  NAVIGATION    = 0
  SPINE         = 1
  MANIFEST      = 2
  SEARCH        = 3

  attr_accessor :placeHolderView, :headerView, :contentPlaceholder, :contentView, :logoImageWell
  attr_accessor :navigationView, :spineView, :manifestView, :searchView, :segmentedControl

  def awakeFromNib
    @views  = [@navigationView, @spineView, @manifestView, @searchView]
    @titles = ["Navigation", "Spine", "Manifest", "Search Results"]
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:nil)
    changeView(NAVIGATION)
    showLogoImage
  end

  def tabViewSelectionDidChange(notification)
    tabView = notification.object
    tabView.selectedTab ? showContentView : showLogoImage
  end

  def showContentView
    @logoImageWell.removeFromSuperview
    @contentPlaceholder.addSubview(@contentView)
    @contentView.frame = @contentPlaceholder.frame
    @contentView.frameOrigin = NSZeroPoint
  end

  def showLogoImage
    @contentView.removeFromSuperview unless @contentPlaceholder.subviews.count == 0
    @logoImageWell.frame = @contentPlaceholder.frame
    @logoImageWell.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@logoImageWell)
  end

  def toggleView(sender)
    if sender.class == NSSegmentedControl
      changeView(sender.selectedSegment)
    else
      changeView(sender.tag)
      @segmentedControl.selectedSegment = sender.tag
    end
  end

  def changeView(index)
    return if @activeView == @views[index]
    oldView = @activeView if @activeView
    @activeView = @views[index]
    @activeView.frame = @placeHolderView.frame
    oldView.animator.alphaValue = 0.0 if oldView
    # oldView.animator.removeFromSuperview if oldView
    @placeHolderView.animator.addSubview(@activeView)
    @activeView.animator.alphaValue = 1.0
    @headerView.title = @titles[index]
  end

  def showSearchResults
    changeView(SEARCH)
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - MINIMUM_WIDTH
  end

  # keep left split pane from resizing as window resizes
  def splitView(sender, resizeSubviewsWithOldSize:oldSize)
    newFrame = sender.frame
    left = sender.subviews[0]
    leftFrame = left.frame
    right = sender.subviews[1]
    rightFrame = right.frame
    leftFrame.size.height = newFrame.size.height
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - sender.dividerThickness
    rightFrame.size.height = newFrame.size.height
    rightFrame.origin.x = leftFrame.size.width + sender.dividerThickness
    left.setFrame(leftFrame)
    right.setFrame(rightFrame)
  end

  def windowShouldClose(sender)
    NSApp.terminate(sender)
  end

end
