class BookWindowController < NSWindowController

  SPLIT_VIEW_MINIMUM_WIDTH = 150.0
  
  attr_accessor :selectionViewController, :navigationController, :spineController, :manifestController
  attr_accessor :tabViewController, :webViewController, :textViewController

  attr_accessor :seletionView, :contentView, :contentPlaceholder
  attr_accessor :segmentedControl, :logoImageWell
  attr_accessor :masterSplitView  
  attr_accessor :renderView, :renderSplitView, :renderImageView

  def init
    initWithWindowNibName("Book")
  end

  def awakeFromNib
    makeResponder(@textViewController)
    makeResponder(@webViewController)
    makeResponder(@tabViewController)
    makeResponder(@selectionViewController)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", 
        name:"TabViewSelectionDidChange", object:@tabViewController.view)
    showLogoImage

    # put selectionView into place
    @selectionViewController.view.frame = @seletionView.frame
    @seletionView.addSubview(selectionViewController.view)
    
    @selectionViewController.expandNavigation(self)
    @selectionViewController.expandSpine(self)
  end

  def windowDidBecomeKey(notification)
    @tabViewController.toggleCloseMenuKeyEquivalents
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
    @tabViewController.view.selectedTab ? showContentView : showLogoImage
  end
  
  def addFiles(sender)
    showSelectionView(self)
    manifestController.showAddFilesSheet(sender)
  end

  def newDirectory(sender)
    showSelectionView(self)
    manifestController.newDirectory(sender)
  end

  def newPoint(sender)
    showSelectionView(self)
    navigationController.newPoint(sender)
  end
  
  def newPointsWithItems(items)
    showSelectionView(self)
    navigationController.newPointsWithItems(items)
  end
  
  def addItemsToSpine(items)
    showSelectionView(self)
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

  def issueViewController
    unless @issueViewController
      @issueViewController = IssueViewController.alloc.initWithBookController(self)
      @issueViewController.loadView
      @issueViewController.view.frame = @seletionView.frame
      @issueViewController.view.hidden = true
      @seletionView.addSubview(@issueViewController.view)
    end
    @issueViewController
  end

  def inspectorViewController
    unless @inspectorViewController
      @inspectorViewController = InspectorViewController.alloc.initWithBookController(self)
      @inspectorViewController.loadView
      frameRect = @seletionView.frame
      frameRect.size.height = inspectorViewController.view.frame.size.height
      @inspectorViewController.view.frame = frameRect
      @inspectorViewController.view.hidden = true
      @seletionView.addSubview(@inspectorViewController.view)
    end
    @inspectorViewController
  end

  def showSelectionView(sender)
    if selectionViewController.view.hidden?
      slideOutView(issueViewController.view, replacingWith:selectionViewController.view, direction:"right")
    end
  end

  def showIssueView(sender)
    if issueViewController.view.hidden?
      slideOutView(selectionViewController.view, replacingWith:issueViewController.view, direction:"left")
    end
  end

  def toggleInspectorView(sender)
    inspectorVisible? ? hideInspectorView : showInspectorView
  end

  def showInspectorView
    # get inspectorView
    inspector = inspectorViewController.view
    
    # get inspectorView height
    inspectorHeight = inspector.frame.size.height

    # make inspectorView visible
    inspector.hidden = false
    
    # position inspectorView below selectionView
    inspector.frameOrigin = [0, -inspectorHeight]
    
    # animate inspectorView sliding up into place
    inspector.animator.frameOrigin = [0, 0]

    # animate selectionView sliding up
    frameRect = selectionViewController.view.frame
    shiftFrameOrigin(frameRect, inspectorHeight)
    selectionViewController.view.animator.frame = frameRect

    # animate issueView sliding up
    frameRect = issueViewController.view.frame
    shiftFrameOrigin(frameRect, inspectorHeight)
    issueViewController.view.animator.frame = frameRect
  end
  
  def hideInspectorView
    # get inspectorView
    inspector = inspectorViewController.view
    
    # get inspectorView height
    inspectorHeight = inspector.frame.size.height

    # animate inspectorView sliding down
    inspector.animator.frameOrigin = [0, -inspectorHeight]

    # animate selectionView sliding down
    frameRect = selectionViewController.view.frame
    shiftFrameOrigin(frameRect, -inspectorHeight)
    selectionViewController.view.animator.frame = frameRect

    # animate issueView sliding down
    frameRect = issueViewController.view.frame
    shiftFrameOrigin(frameRect, -inspectorHeight)
    issueViewController.view.animator.frame = frameRect

    # make inspectorView invisible
    inspector.animator.hidden = true
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
    if document.isDocumentEdited
      alert = NSAlert.alertWithMessageText("Your changes must be saved before validation.", 
          defaultButton:"Save and Validate", alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:'')
      alert.beginSheetModalForWindow(window, modalDelegate:self, 
          didEndSelector:"validateSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
    else
      performValidation
    end
  end
  
  def validateSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSOKButton
      alert.window.orderOut(self)
      document.saveDocument(self)
      performValidation
    end
  end
  
  def performValidation
    @validationController ||= ValidationController.alloc.init
    @validationController.validateBook(document, @textViewController.lineNumberView)
    issueViewController.refresh
    showIssueView(self)    
  end
  
  def printDocument(sender)
    PrintController.printView(@tabViewController.selectedTabPrintView)
  end

  def runModalAlert(messageText, informativeText='')
    Alert.runModal(window, messageText, informativeText)
  end

  def makeResponder(controller)
    current = window.nextResponder
    window.nextResponder = controller
    controller.nextResponder = current
  end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"toggleInspectorView:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = inspectorVisible? ? "Hide Inspector" : "Show Inspector"
      end
    when :"printDocument:"
      @tabViewController.numberOfTabs > 0
    else
      true
    end
  end

  private
  
  def inspectorVisible?
    !inspectorViewController.view.hidden?
  end
  
  def shiftFrameOrigin(frame, amount)
    frame.size.height -= amount
    frame.origin.y += amount
  end

  def slideOutView(outView, replacingWith:inView, direction:direction)
    NSAnimationContext.beginGrouping
    
    # NSAnimationContext.currentContext.duration = 3.0
    
    # get selectionView width
    selectionViewWidth = @seletionView.frame.size.width
    
    # start inView far right or left
    inFrame = @seletionView.frame
    inFrame.origin.x = (direction == "right") ? -selectionViewWidth : selectionViewWidth
    shiftFrameOrigin(inFrame, inspectorViewController.view.frame.size.height) if inspectorVisible?
    inView.frame = inFrame
    
    # make inView visible
    inView.hidden = false

    # animate inView sliding into place
    inFrame = inFrame.dup
    inFrame.origin.x = 0
    inView.animator.frame = inFrame
    inView.animator.alphaValue = 1.0
    
    # animate outView sliding out to right or left
    outFrame = @seletionView.frame
    outFrame.origin.x = (direction == "right") ? selectionViewWidth : -selectionViewWidth
    shiftFrameOrigin(outFrame, inspectorViewController.view.frame.size.height) if inspectorVisible?
    outView.animator.frame = outFrame
    outView.animator.alphaValue = 0.5
    
    # make outView invisible
    outView.animator.hidden = true

    NSAnimationContext.endGrouping
  end

end