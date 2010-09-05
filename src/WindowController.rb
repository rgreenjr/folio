class WindowController < NSWindowController

  NAVIGATION = 0
  SPINE      = 1
  MANIFEST   = 2
  MINIMUM_WIDTH = 250.0

  attr_accessor :splitView, :segementedControl
  attr_accessor :placeHolderView, :navigationView, :spineView, :manifestView
  attr_accessor :textView

  def awakeFromNib
    @splitView.delegate = self
    showNavigation(self)
  end

  def toggleView(sender)
    if @segementedControl.selectedSegment == NAVIGATION && @currentScrollView != @navigationView
      @currentScrollView = @navigationView
    elsif @segementedControl.selectedSegment == SPINE && @currentScrollView != @spineView
      @currentScrollView = @spineView
    elsif @segementedControl.selectedSegment == MANIFEST && @currentScrollView != @manifestView
      @currentScrollView = @manifestView
    end
    subviews = @placeHolderView.subviews
    subviews.objectAtIndex(0).removeFromSuperview if subviews.size > 0
    @placeHolderView.addSubview(@currentScrollView)
    @currentScrollView.setFrame(@currentScrollView.superview.frame)
  end

  def showNavigation(sender)
    @segementedControl.selectedSegment = NAVIGATION
    toggleView(self)
  end

  def showSpine(sender)
    @segementedControl.selectedSegment = SPINE
    toggleView(self)
  end

  def showManifest(sender)
    @segementedControl.selectedSegment = MANIFEST
    toggleView(self)
  end

  # NSSplitViewDelegate methods

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - MINIMUM_WIDTH
  end

  def splitView(sender, resizeSubviewsWithOldSize:oldSize)
    hasRight = @splitView.subviews.size > 2

  	newFrame = @splitView.frame

    left = @splitView.subviews[0]
    leftFrame = left.frame

    middle = @splitView.subviews[1]
    middleFrame = middle.frame

    if hasRight
      right = @splitView.subviews[2]
      rightFrame = right.frame
    end

    dividerThickness = @splitView.dividerThickness

    leftFrame.size.height = newFrame.size.height

    if hasRight
      middleFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness - rightFrame.size.width - dividerThickness
    else
      middleFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness
    end
    middleFrame.size.width = MINIMUM_WIDTH if middleFrame.size.width < MINIMUM_WIDTH
    middleFrame.size.height = newFrame.size.height
    middleFrame.origin.x = leftFrame.size.width + dividerThickness

    if hasRight
      rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness - middleFrame.size.width - dividerThickness
      rightFrame.size.width = MINIMUM_WIDTH if rightFrame.size.width < MINIMUM_WIDTH
      rightFrame.size.height = newFrame.size.height
      rightFrame.origin.x = leftFrame.size.width + dividerThickness + middleFrame.size.width + dividerThickness
    end

    left.setFrame(leftFrame)
    middle.setFrame(middleFrame)
    if hasRight
      right.setFrame(rightFrame)
    end
  end

  def toggleSourceView(sender)
    @splitView.subviews.size > 2 ? hideSourceView : showSourceView
  end
  
  def hideSourceView
    left   = @splitView.subviews[0]
    middle = @splitView.subviews[1]
    right  = @splitView.subviews[2]

    leftFrame   = left.frame
    middleFrame = middle.frame
    rightFrame  = right.frame

    dividerThickness = @splitView.dividerThickness

    leftFrame.size.height = @splitView.frame.size.height
    leftFrame.size.width = leftFrame.size.width

    middleFrame.size.width = @splitView.frame.size.width - leftFrame.size.width - dividerThickness
    middleFrame.origin.x = leftFrame.size.width + dividerThickness

    rightFrame.size.width = 0
    rightFrame.origin.x = leftFrame.size.width + dividerThickness + middleFrame.size.width + dividerThickness

    left.setFrame(leftFrame)
    middle.setFrame(middleFrame)

    right.removeFromSuperview
  end
  
  def showSourceView
    left   = @splitView.subviews[0]
    middle = @splitView.subviews[1]

    leftFrame   = left.frame
    middleFrame = middle.frame
    rightFrame  = NSRect.new

    dividerThickness = @splitView.dividerThickness

    leftFrame.size.height = @splitView.frame.size.height
    leftFrame.size.width = leftFrame.size.width

    middleFrame.size.width = (@splitView.frame.size.width - leftFrame.size.width - dividerThickness) * 0.5
    middleFrame.origin.x = leftFrame.size.width + dividerThickness

    rightFrame.size.width = middleFrame.origin.x + 1 + dividerThickness
    rightFrame.origin.x = middleFrame.size.width

    left.setFrame(leftFrame)
    middle.setFrame(middleFrame)
    @textView.setFrame(middleFrame)

    @splitView.addSubview(@textView)
  end

end
