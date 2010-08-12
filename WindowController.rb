class WindowController < NSWindowController

  attr_accessor :placeHolderView, :entryScrollView, :layoutScrollView

  def awakeFromNib
    toggleView(self)
  end

  def toggleView(sender)
    subviews = @placeHolderView.subviews
    subviews.objectAtIndex(0).removeFromSuperview if subviews.size > 0
    @placeHolderView.displayIfNeeded
    
    currentView = (currentView == layoutScrollView) ? entryScrollView : currentView = layoutScrollView
    @placeHolderView.addSubview(currentView)
    
		newBounds = NSRect.new
		newBounds.origin.x = 0
		newBounds.origin.y = 0
		newBounds.size.width = currentView.superview.frame.size.width
		newBounds.size.height = currentView.superview.frame.size.height
		currentView.setFrame(currentView.superview.frame)

    currentView.setFrameOrigin(NSMakePoint(0, 0))
		currentView.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    120.0
  end
    
  def previousPage(sender)
    puts "previousPage"
    tableView = @placeHolderView.subviews.objectAtIndex(0).subviews.objectAtIndex(0).subviews.objectAtIndex(0)
    p tableView
    puts tableView.selectedRow
    #@bookController.select
  end
  
  def nextPage(sender)
    puts "nextPage"
  end
  
end