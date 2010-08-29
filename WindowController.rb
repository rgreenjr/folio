class WindowController < NSWindowController
  
  NAVIGATION = 0
  SPINE      = 1
  MANIFEST   = 2

  attr_accessor :splitView, :segementedControl
  attr_accessor :placeHolderView, :navigationView, :spineView, :manifestView

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

	def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    # puts "splitView(#{sender}, constrainMinCoordinate:#{proposedMin}, ofSubviewAt:#{offset})"
    if offset == NAVIGATION
      return [150, proposedMin].max
    else
      return [500, proposedMin].max
    end
  end
	
	def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    # puts "splitView(#{sender}, constrainMaxCoordinate:#{proposedMax}, ofSubviewAt:#{offset})"
    proposedMax
  end
	
end
