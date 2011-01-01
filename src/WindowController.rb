class WindowController < NSWindowController

  attr_accessor :contentPlaceholder, :contentView, :logoImageWell, :fileSearchField

  def awakeFromNib
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:nil)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'fileSearchFieldTextDidChange:', name:NSControlTextDidChangeNotification, object:@fileSearchField)
    showLogoImage
  end

  def tabViewSelectionDidChange(notification)
    tabView = notification.object
    tabView.selectedTab ? showContentView : showLogoImage
  end

  def showContentView
    @logoImageWell.removeFromSuperview
    @contentPlaceholder.addSubview(@contentView)
    @contentView.frame = @contentPlaceholder.frame
    @contentView.frameOrigin = NSZeroPoint
  end

  def showLogoImage
    @contentView.removeFromSuperview unless @contentPlaceholder.subviews.count == 0
    @logoImageWell.frame = @contentPlaceholder.frame
    @logoImageWell.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@logoImageWell)
  end

end
