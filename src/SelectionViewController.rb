class SelectionViewController < NSViewController
  
  attr_accessor :segmentedControl, :tabView
  
  def awakeFromNib
    showNavigationView(self)
  end
  
  def book=(book)
    @book = book
    @navigationController.book = book if @navigationController
    @spineController.book = book if @spineController
    @manifestController.book = book if @manifestController
    @searchController.book = book if @searchController
  end
  
  def showNavigationView(sender)
    unless @navigationController
      @navigationController ||= NavigationController.alloc.init
      @navigationController.loadView
      @navigationController.tabView = @tabView
      @navigationController.book = @book
    end
    changeController(@navigationController)
  end

  def showSpineView(sender)
    unless @spineController
      @spineController ||= SpineController.alloc.init
      @spineController.loadView
      @spineController.tabView = @tabView
      @spineController.book = @book
    end
    changeController(@spineController)
  end

  def showManifestView(sender)
    unless @manifestController
      @manifestController ||= ManifestController.alloc.init
      @manifestController.loadView
      @manifestController.tabView = @tabView
      @manifestController.book = @book
    end
    changeController(@manifestController)
  end

  def showSearchView(sender)
    unless @searchController
      @searchController ||= SearchController.alloc.init
      @searchController.loadView
      @searchController.tabView = @tabView
      @searchController.book = @book
    end
    changeController(@searchController)
  end

  def changeController(controller)
    controller.view.frame = view.frame
    # view.subviews.first.animator.alphaValue = 0.0 unless view.subviews.empty?
    view.subviews.first.removeFromSuperview unless view.subviews.empty?
    view.animator.addSubview(controller.view)
    # controller.view.animator.alphaValue = 1.0
  end
  
  # def toggleView(sender)
  #   if sender.class == NSSegmentedControl
  #     changeView(sender.selectedSegment)
  #   else
  #     changeView(sender.tag)
  #     @segmentedControl.selectedSegment = sender.tag
  #   end
  # end
  
  # def fileSearchFieldTextDidChange(notification)
  #   value = @fileSearchField.stringValue
  #   value = nil if value.empty?
  #   NSNotificationCenter.defaultCenter.postNotificationName("FileSearchTextDidChange", object:value)
  # end

end

