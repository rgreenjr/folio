class WindowController < NSWindowController

  attr_accessor :placeHolderView, :entryScrollView, :layoutScrollView

  def awakeFromNib
    toggleView(self)
  end

  def toggleView(sender)
    if @currentScrollView == @layoutScrollView
      @currentScrollView = @entryScrollView
    else
      @currentScrollView = @layoutScrollView
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
    puts "previousPage"
    puts currentTableView.selectedRow
  end
  
  def nextPage(sender)
    puts "nextPage"
  end
  
  private
  
  def currentTableView
    @currentScrollView.subviews.objectAtIndex(0).subviews.objectAtIndex(0)
  end
  
end