class WindowController < NSWindowController
  
  NAVIGATION = 0
  SPINE      = 1
  MANIFEST   = 2

  attr_accessor :placeHolderView, :navigationScrollView, :spineScrollView, :manifestScrollView
  attr_accessor :previousPageToolbarItem, :nextPageToolbarItem, :segementedControl

  def awakeFromNib
    showNavigation(self)
  end

  def toggleView(sender)
    if @segementedControl.selectedSegment == NAVIGATION && @currentScrollView != @navigationScrollView
      @currentScrollView = @navigationScrollView
    elsif @segementedControl.selectedSegment == SPINE && @currentScrollView != @spineScrollView
      @currentScrollView = @spineScrollView
    elsif @segementedControl.selectedSegment == MANIFEST && @currentScrollView != @manifestScrollView
      @currentScrollView = @manifestScrollView
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

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    120.0
  end
    
end
