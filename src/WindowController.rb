class WindowController < NSWindowController

  NAVIGATION = 0
  SPINE      = 1
  MANIFEST   = 2
  SEARCH     = 3
  MINIMUM_WIDTH = 250.0

  attr_accessor :splitView, :segementedControl
  attr_accessor :placeHolderView, :navigationView, :spineView, :manifestView, :searchView
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
    elsif @segementedControl.selectedSegment == SEARCH && @currentScrollView != @searchView
      @currentScrollView = @searchView
    end
    subviews = @placeHolderView.subviews
    subviews[0].removeFromSuperview unless subviews.empty?
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
  
  def showSearch(sender)
    @segementedControl.selectedSegment = SEARCH
    toggleView(self)
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - MINIMUM_WIDTH
  end
  
end
