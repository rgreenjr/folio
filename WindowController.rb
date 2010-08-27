class WindowController < NSWindowController

  attr_accessor :placeHolderView, :navigationScrollView, :spineScrollView, :manifestScrollView
  attr_accessor :previousPageToolbarItem, :nextPageToolbarItem, :segementedControl

  def awakeFromNib
    @currentScrollView = @navigationScrollView
  end

  def toggleView(sender)
    if @segementedControl.selectedSegment == 0 && @currentScrollView != @navigationScrollView
      @currentScrollView = @navigationScrollView
    elsif @segementedControl.selectedSegment == 1 && @currentScrollView != @spineScrollView
      @currentScrollView = @spineScrollView
    elsif @segementedControl.selectedSegment == 2 && @currentScrollView != @manifestScrollView
      @currentScrollView = @manifestScrollView
    end
    subviews = @placeHolderView.subviews
    subviews.objectAtIndex(0).removeFromSuperview if subviews.size > 0    
    @placeHolderView.addSubview(@currentScrollView)
		@currentScrollView.setFrame(@currentScrollView.superview.frame)
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    120.0
  end
    
  def previousPage(sender)
  end
  
  def nextPage(sender)
  end
  
  def validateToolbarItem(toolbarItem)
    # return true unless @currentScrollView == @manifestScrollView
    # return (toolbarItem != @previousPageToolbarItem && toolbarItem != @nextPageToolbarItem)
  end
  
  private
  
  def currentTableView
    @currentScrollView.subviews.objectAtIndex(0).subviews.objectAtIndex(0)
  end
  
end
