class WindowController < NSWindowController

  NAVIGATION = 0
  SPINE      = 1
  MANIFEST   = 2

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

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
  	subviewFrame = sender.subviews.objectAtIndex(offset).frame
    frameOrigin = subviewFrame.origin.x
  	return frameOrigin + minimumSize(offset)
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
  	growingSubviewFrame = sender.subviews.objectAtIndex(offset).frame
  	shrinkingSubviewFrame = sender.subviews.objectAtIndex(offset + 1).frame
    currentCoordinate = growingSubviewFrame.origin.x + growingSubviewFrame.size.width
    shrinkingSize = shrinkingSubviewFrame.size.width
  	return currentCoordinate + (shrinkingSize - minimumSize(offset))
  end

  def toggleSourceView(sender)
    newFrame = @textView.frame
    newFrame.origin.x += newFrame.size.width
    newFrame.size.width = 0
    windowResize = {NSViewAnimationTargetKey => @textView, NSViewAnimationEndFrameKey => NSValue.valueWithRect(newFrame)}
    animation = NSViewAnimation.alloc.initWithViewAnimations([windowResize])
    animation.setAnimationBlockingMode(NSAnimationBlocking)
    animation.startAnimation
    @textView.animator.removeFromSuperview
    @splitView.needsDisplay = true
  end
  
  private
  
  def minimumSize(frameIndex)
    @frameSizes ||= [250.0, 400.0, 400.0][frameIndex]
  end

end
