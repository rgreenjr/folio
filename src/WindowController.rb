class WindowController < NSWindowController

  MINIMUM_WIDTH = 250.0

  attr_accessor :placeHolderView, :navigationView, :spineView, :manifestView, :searchView

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
    end
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - MINIMUM_WIDTH
  end
  
end
