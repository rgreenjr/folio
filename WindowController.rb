class WindowController < NSWindowController

  attr_accessor :placeHolderView, :layoutScrollView, :spineScrollView, :manifestScrollView
  attr_accessor :previousPageToolbarItem, :nextPageToolbarItem

  def awakeFromNib
    @currentScrollView = @layoutScrollView
  end

  def toggleView(sender)
    if sender.selectedSegment == 0 && @currentScrollView != @layoutScrollView
      @currentScrollView = @layoutScrollView
    elsif sender.selectedSegment == 1 && @currentScrollView != @spineScrollView
      @currentScrollView = @spineScrollView
    elsif sender.selectedSegment == 2 && @currentScrollView != @manifestScrollView
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
    currentTableView.dataSource.showPrevious
  end
  
  def nextPage(sender)
    currentTableView.dataSource.showNext
  end
  
  def validateToolbarItem(toolbarItem)
    return true unless @currentScrollView == @manifestScrollView
    return (toolbarItem != @previousPageToolbarItem && toolbarItem != @nextPageToolbarItem)
  end
  
  private
  
  def currentTableView
    @currentScrollView.subviews.objectAtIndex(0).subviews.objectAtIndex(0)
  end
  
end
