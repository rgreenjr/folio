class BookWindowController < NSWindowController

  SPLIT_VIEW_MINIMUM_WIDTH = 150.0

  attr_accessor :seletionView, :contentView, :tabView, :contentPlaceholder
  attr_accessor :segmentedControl, :logoImageWell, :fileSearchField
  attr_accessor :textViewController, :webViewController, :tabViewControler
  
  attr_accessor :renderView, :renderSplitView, :renderImageView

  def init
    initWithWindowNibName("Book")
  end

  def awakeFromNib
    makeResponder(@textViewController)
    makeResponder(@webViewController)
    makeResponder(@tabViewControler)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:@tabView)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'fileSearchFieldTextDidChange:', name:NSControlTextDidChangeNotification, object:@fileSearchField)
    showLogoImage
    showNavigationView(self)
  end

  def windowTitleForDocumentDisplayName(displayName)
    document.metadata.title
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + SPLIT_VIEW_MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - SPLIT_VIEW_MINIMUM_WIDTH
  end

  # keep left split pane from resizing as window resizes
  def splitView(sender, resizeSubviewsWithOldSize:oldSize)
    right = sender.subviews[1]
    rightFrame = right.frame
    rightFrame.size.width += sender.frame.size.width - oldSize.width
    right.frame = rightFrame
    sender.adjustSubviews
  end
  
  def tabViewSelectionDidChange(notification)
    @tabView.selectedTab ? showContentView : showLogoImage
  end

  def showContentView
    @logoImageWell.removeFromSuperview
    @contentPlaceholder.addSubview(@contentView)
    @contentView.frame = @contentPlaceholder.frame
    @contentView.frameOrigin = NSZeroPoint
    if @tabView.selectedTab.item.imageable?
      @renderSplitView.removeFromSuperview
      @renderView.addSubview(@renderImageView)
      @renderImageView.frame = @renderView.frame
      @renderImageView.frameOrigin = NSZeroPoint
    else
      @renderImageView.removeFromSuperview
      @renderView.addSubview(@renderSplitView)
      @renderSplitView.frame = @renderView.frame
      @renderSplitView.frameOrigin = NSZeroPoint
    end
  end

  def showLogoImage
    @contentView.removeFromSuperview unless @contentPlaceholder.subviews.count == 0
    @logoImageWell.frame = @contentPlaceholder.frame
    @logoImageWell.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@logoImageWell)
  end

  def showMetadataPanel(sender)
    @metadataController ||= MetadataController.alloc.init
    @metadataController.book = document
    @metadataController.window
    @metadataController.showWindow(self)
  end

  def showProgressWindow(title, &block)
    @progressController ||= ProgressController.alloc.init
    @progressController.window
    @progressController.showWindow(title, &block)
  end

  def navigationController
    unless @navigationController
      @navigationController = NavigationController.alloc.init
      @navigationController.loadView
      @navigationController.tabView = @tabView
      @navigationController.book = document
    end
    @navigationController
  end

  def spineController
    unless @spineController
      @spineController = SpineController.alloc.init
      @spineController.loadView
      @spineController.tabView = @tabView
      @spineController.book = document
    end
    @spineController
  end

  def manifestController
    unless @manifestController
      @manifestController = ManifestController.alloc.init
      @manifestController.loadView
      @manifestController.tabView = @tabView
      @manifestController.book = document
    end
    @manifestController
  end

  def searchController
    unless @searchController
      @searchController = SearchController.alloc.init
      @searchController.loadView
      @searchController.tabView = @tabView
      @searchController.book = document
    end
    @searchController
  end

  def showNavigationView(sender)
    changeSelectionView(navigationController)
  end

  def showSpineView(sender)
    changeSelectionView(spineController)
  end

  def showManifestView(sender)
    changeSelectionView(manifestController)
  end

  def showSearchView(sender)
    changeSelectionView(searchController)
  end

  def showUnregisteredFiles(sender)
    manifestController.showUnregisteredFiles
  end

  def showTemporaryDirectory(sender)
    system("open \"#{document.unzippath}\"")
  end

  def validate(sender)
    # showProgressWindow("Validating...") do
    #   result = Validator.validate(@book)
    #   puts result
    # end
  end

  private

  def changeSelectionView(controller)
    controller.view.frame = @seletionView.frame
    @seletionView.subviews.first.removeFromSuperview unless @seletionView.subviews.empty?
    @seletionView.addSubview(controller.view)
  end

  def makeResponder(controller)
    current = window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
  end
  
end
