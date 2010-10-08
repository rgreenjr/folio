class WindowController < NSWindowController

  MINIMUM_WIDTH = 250.0

  attr_accessor :placeHolderView, :headerView
  attr_accessor :navigationView, :spineView, :manifestView, :searchView

  def awakeFromNib
    @views = [@navigationView, @spineView, @manifestView, @searchView]
    toggleView(nil)
  end

  def toggleView(sender)
    index = sender ? sender.tag : 0
    unless @activeView == @views[index]
      @activeView = @views[index]
      subviews = @placeHolderView.subviews
      subviews[0].removeFromSuperview unless subviews.empty?
      @placeHolderView.addSubview(@activeView)
      @activeView.frame = @activeView.superview.frame
      @headerView.title = "Fooooo"
    end
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
  
end
