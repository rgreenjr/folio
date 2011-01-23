class BookWindowController < NSWindowController

  SPLIT_VIEW_MINIMUM_WIDTH = 150.0
  
  attr_accessor :masterSplitView

  attr_accessor :seletionView, :contentView, :tabView, :contentPlaceholder
  attr_accessor :segmentedControl, :logoImageWell
  attr_accessor :textViewController, :webViewController, :tabViewController
  
  attr_accessor :renderView, :renderSplitView, :renderImageView

  def init
    initWithWindowNibName("Book")
  end

  def awakeFromNib
    makeResponder(@textViewController)
    makeResponder(@webViewController)
    makeResponder(@tabViewController)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:@tabView)
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
    right = @masterSplitView.subviews.last
    rightFrame = right.frame
    rightFrame.size.width += @masterSplitView.frame.size.width - oldSize.width
    right.frame = rightFrame
    @masterSplitView.adjustSubviews
  end
  
  def tabViewSelectionDidChange(notification)
    @tabView.selectedTab ? showContentView : showLogoImage
  end
  
  def addFiles(sender)
    showManifestView(self)
    manifestController.showAddFilesSheet(sender)
  end

  def newDirectory(sender)
    showManifestView(self)
    manifestController.newDirectory(sender)
  end

  def newPoint(sender)
    showNavigationView(self)
    navigationController.newPoint(sender)
  end
  
  def newPointsWithItems(items)
    showNavigationView(self)
    navigationController.newPointsWithItems(items)
  end
  
  def addItemsToSpine(items)
    showSpineView(self)
    spineController.addItems(items)
  end

  def showContentView
    @logoImageWell.removeFromSuperview
    @contentPlaceholder.addSubview(@contentView)
    @contentView.frame = @contentPlaceholder.frame
    @contentView.frameOrigin = NSZeroPoint
    if @tabViewController.selectedItem.imageable?
      @renderSplitView.removeFromSuperview
      newView = @renderImageView
    else
      @renderImageView.removeFromSuperview
      newView = @renderSplitView
    end
    @renderView.addSubview(newView)
    newView.frame = @renderView.frame
    newView.frameOrigin = NSZeroPoint
    @masterSplitView.adjustSubviews
  end

  def showLogoImage
    @contentView.removeFromSuperview unless @contentPlaceholder.subviews.count == 0
    @logoImageWell.frame = @contentPlaceholder.frame
    @logoImageWell.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@logoImageWell)
  end

  def showMetadataPanel(sender)
    @metadataController ||= MetadataController.alloc.initWithBookController(self)
    @metadataController.showMetadataSheet(self)
  end

  def navigationController
    @navigationController ||= NavigationController.alloc.initWithBookController(self)
  end

  def spineController
    @spineController ||= SpineController.alloc.initWithBookController(self)
  end

  def manifestController
    @manifestController ||= ManifestController.alloc.initWithBookController(self)
  end
  
  def issueViewController
    @issueViewController ||= IssueViewController.alloc.initWithBookController(self).loadView
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
  
  def showIssueView(sender)
    changeSelectionView(issueViewController)
  end

  def showSearchView(sender)
    changeSelectionView(searchController)
  end

  def showUnregisteredFiles(sender)
    manifestController.showUndeclaredFilesSheet
  end

  def showTemporaryDirectory(sender)
    NSTask.launchedTaskWithLaunchPath("/usr/bin/open", arguments:[document.unzipPath])
  end

  def showProgressWindow(title, &block)
    @progressController ||= ProgressController.alloc.init
    @progressController.showWindowWithTitle(title, &block)
  end

  def validate(sender)
    @validationController ||= ValidationController.alloc.init
    @validationController.validateBook(document, @textViewController.lineNumberView)
    issueViewController.refresh
    showIssueView(self)
  end
  
  def runModalAlert(messageText, informativeText='')
    Alert.runModal(window, messageText, informativeText)
  end
  
  # def validateUserInterfaceItem(interfaceItem)
  #   case interfaceItem.action
  #   when :"showNavigationView:"
  #     @seletionView.subviews.first != navigationController.view
  #   when :"showSpineView:"
  #     @seletionView.subviews.first != spineController.view
  #   when :"showManifestView:"
  #     @seletionView.subviews.first != manifestController.view
  #   else
  #     true
  #   end
  # end
  # 
  # def updateToolbarItems
  #   window.toolbar.visibleItems.each do |view|
  #     if view.isKindOfClass(NSToolbarItem)
  #       view.enabled = validateUserInterfaceItem(view)
  #     end
  #   end
  # end

  private

  def changeSelectionViewXXXXX(controller)
    if @seletionView.subviews.empty?
      controller.view.frame = @seletionView.frame
      @seletionView.addSubview(controller.view)
    else
      currentView = @seletionView.subviews.first
      if controller.view != currentView
        controller.view.frame = @seletionView.frame
        @seletionView.animator.replaceSubview(currentView, with:controller.view)
      end
    end
  end

  def changeSelectionView(controller)
    if @currentSelectionView
      return if @currentSelectionView == controller.view
      oldView = @currentSelectionView
    end
    @currentSelectionView = controller.view

    unless @seletionView.subviews.include? @currentSelectionView
      @currentSelectionView.frame = @seletionView.frame
      @seletionView.addSubview(@currentSelectionView)
    end
    
    @currentSelectionView.hidden = false
    
    if oldView
      if oldView == navigationController.view
        slideViews(oldView, @currentSelectionView, :left)
      elsif oldView == manifestController.view
        if @currentSelectionView == issueViewController.view
          slideViews(oldView, @currentSelectionView, :left)
        else
          slideViews(oldView, @currentSelectionView, :right)
        end
      elsif oldView == spineController.view
        if @currentSelectionView == navigationController.view
          slideViews(oldView, @currentSelectionView, :right)
        else
          slideViews(oldView, @currentSelectionView, :left)
        end
      elsif oldView == issueViewController.view
        slideViews(oldView, @currentSelectionView, :right)
      elsif @currentSelectionView == navigationController.view
        slideViews(oldView, @currentSelectionView, :right)
      else
        slideViews(oldView, @currentSelectionView, :left)
      end
    end
  end
  
  def slideViews(oldView, newView, direction)
    # start newView far right or left
    rightFrame = @seletionView.frame    
    rightFrame.origin.x = direction == :right ? -@seletionView.frame.size.width : @seletionView.frame.size.width
    newView.frame = rightFrame
    
    # animate newView sliding into place
    leftFrame = @seletionView.frame
    newView.animator.frame = leftFrame
    
    # animate oldView sliding out to right or left
    outFrame = @seletionView.frame
    outFrame.origin.x = direction == :right ? @seletionView.frame.size.width : -@seletionView.frame.size.width
    oldView.animator.frame = outFrame
    oldView.animator.hidden = true
  end

  def makeResponder(controller)
    current = window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
    controller.bookController = self
  end
  
end
