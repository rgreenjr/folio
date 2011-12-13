class BookWindowController < NSWindowController

  ISSUE_VIEW_MIN_HEIGHT    = 100.0
  SELECTION_VIEW_MIN_WIDTH = 150.0
  
  attr_accessor :navigationController
  attr_accessor :spineController
  attr_accessor :manifestController

  attr_accessor :tabViewController
  attr_accessor :webViewController
  attr_accessor :textViewController
  attr_accessor :metadataController

  attr_accessor :masterSplitView # contains selectionView (left) and contentSplitView (right)

  attr_accessor :selectionView
  attr_accessor :selectionViewController
  
  attr_accessor :contentSplitView # contains contentPlaceholder (top) and issueView (bottom)

  attr_accessor :contentPlaceholder # contains either logoImageWell or contentView
  
  attr_accessor :logoImageWell
  
  attr_accessor :contentView # tabBox with tabView (top) and renderView (bottom)  
  attr_accessor :renderView # contains either renderSplitView or renderImageView
  attr_accessor :renderSplitView # contains textView (top) and webView (bottom)
  attr_accessor :renderImageView
  
  attr_accessor :inspectorButton, :issueButton

  def init
    initWithWindowNibName("Book")
  end

  def awakeFromNib    
    # add controllers to the next responder event chain
    makeResponder(@textViewController)
    makeResponder(@webViewController)
    makeResponder(@tabViewController)
    makeResponder(@selectionViewController)
    
    # register for tabView selection change events
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", 
        name:"TabViewSelectionDidChange", object:@tabViewController.view)
        
    # show logo in content area by default
    showLogoImage

    # put selectionView into place
    @selectionViewController.view.frame = @selectionView.frame
    @selectionView.addSubview(selectionViewController.view)
    
    # exapnd all selectionView elements
    @selectionViewController.expandNavigation(self)
    @selectionViewController.expandSpine(self)
    @selectionViewController.expandManifest(self)
    
    # force issueView to load
    issueViewController
    
    window.makeKeyAndOrderFront(nil)
  end

  def windowDidBecomeKey(notification)
    @tabViewController.toggleCloseMenuKeyEquivalents
  end

  def windowTitleForDocumentDisplayName(displayName)
    document.metadata.title
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    if sender == @masterSplitView
      proposedMin + SELECTION_VIEW_MIN_WIDTH
    else
      proposedMin + ISSUE_VIEW_MIN_HEIGHT
    end
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    if sender == @masterSplitView
      proposedMax - SELECTION_VIEW_MIN_WIDTH
    else
      proposedMax - ISSUE_VIEW_MIN_HEIGHT
    end
  end

  # keep left split pane from resizing as window resizes
  def splitView(sender, resizeSubviewsWithOldSize:oldSize)
    if sender == @masterSplitView
      right = @masterSplitView.subviews.last
      rightFrame = right.frame
      rightFrame.size.width += @masterSplitView.frame.size.width - oldSize.width
      right.frame = rightFrame
      @masterSplitView.adjustSubviews
    else
      @contentSplitView.adjustSubviews
    end
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
  
  def showContentView
    # remove the logo view
    @logoImageWell.removeFromSuperview
    
    # add contentView to contentPlaceholder view
    @contentPlaceholder.addSubview(@contentView)
    
    # make contentView fill entire frame
    @contentView.frame = @contentPlaceholder.frame
    @contentView.frameOrigin = NSZeroPoint
    
    if @tabViewController.selectedItem.imageable?
      # remove combo text/web view since content is image
      @renderSplitView.removeFromSuperview
      
      # set newView to image view
      newView = @renderImageView
    else
      # remove image view since content is not image
      @renderImageView.removeFromSuperview
      
      # set newView to text/combo view
      newView = @renderSplitView
    end
    
    # add newView to renderView
    @renderView.addSubview(newView)
    
    # make newView fill entire frame
    newView.frame = @renderView.frame
    newView.frameOrigin = NSZeroPoint
    
    # adjust masterSplitView
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
      @issueViewController.view.frame = @contentSplitView.subviews.last.frame
      
      # remove the bottom placeholder view
      @contentSplitView.subviews.last.removeFromSuperview      
      @contentSplitView.adjustSubviews
    end
    @issueViewController
  end

  def toggleIssueView(sender)
    issueViewController.visible? ? hideIssueView : showIssueView
  end

  def showIssueView
    # why is this necessary?
    f = issueViewController.view.frame
    f.size.height += 48.0
    issueViewController.view.frame = f

    @contentSplitView.addSubview(issueViewController.view)
    @contentSplitView.adjustSubviews    
    @issueButton.state = NSOnState
  end
  
  def hideIssueView
    issueViewController.view.removeFromSuperview      
    @contentSplitView.adjustSubviews
    @issueButton.state = NSOffState
  end

  def inspectorViewController
    unless @inspectorViewController
      @inspectorViewController = InspectorViewController.alloc.initWithBookController(self)
      @inspectorViewController.loadView
      frameRect = @selectionView.frame
      @inspectorViewController.view.hidden = true
      frameRect.size.height = @inspectorViewController.view.frame.size.height
      @inspectorViewController.view.frame = frameRect
      @selectionView.addSubview(@inspectorViewController.view)
    end
    @inspectorViewController
  end

  def toggleInspectorView(sender)
    inspectorViewController.visible? ? hideInspectorView : showInspectorView
  end

  def showInspectorView
    # get inspectorView
    inspector = inspectorViewController.view
    
    return if inspector.frame.origin.y > 0

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
    
    @inspectorButton.state = NSOffState
  end
  
  def hideInspectorView
    # get inspectorView
    inspector = inspectorViewController.view
    
    return if inspector.frame.origin.y < 0
    
    # get inspectorView height
    inspectorHeight = inspector.frame.size.height

    # animate inspectorView sliding down
    inspector.animator.frameOrigin = [0, -inspectorHeight]

    # animate selectionView sliding down
    frameRect = selectionViewController.view.frame
    shiftFrameOrigin(frameRect, -inspectorHeight)
    selectionViewController.view.animator.frame = frameRect

    # make inspectorView invisible
    inspector.animator.hidden = true
    
    @inspectorButton.state = NSOnState
  end

  def showUnregisteredFiles(sender)
    manifestController.showUndeclaredFilesSheet
  end

  def showStagingDirectory(sender)
    NSTask.launchedTaskWithLaunchPath("/usr/bin/open", arguments:[document.unzipPath])
  end

  def searchWikipedia(sender)
    url = NSURL.URLWithString("http://en.wikipedia.org/wiki/Special:Search/#{document.metadata.title.urlEscape}")
    NSWorkspace.sharedWorkspace.openURL(url)
  end

  def searchGoogle(sender)
    url = NSURL.URLWithString("http://www.google.com/search?q=#{document.metadata.title.urlEscape}")
    NSWorkspace.sharedWorkspace.openURL(url)
  end

  def searchAmazon(sender)
    url = NSURL.URLWithString("http://www.amazon.com/s?field-keywords=#{document.metadata.title.urlEscape}")
    NSWorkspace.sharedWorkspace.openURL(url)
  end

  def showProgressWindow(title, &block)
    @progressController ||= ProgressController.alloc.init
    @progressController.showWindowWithTitle(title, &block)
  end

  def validate(sender)
    if document.isDocumentEdited
      alert = NSAlert.alloc.init
      alert.messageText = "Your changes need to be saved prior to validation."
      alert.addButtonWithTitle("Save and Validate")
      alert.addButtonWithTitle("Cancel")
      alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:"validateSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
    elsif document.fileURL.nil?
      alert = NSAlert.alloc.init
      alert.messageText = "The book must be saved before it can be validated."
      alert.addButtonWithTitle("OK")
      alert.beginSheetModalForWindow(window, modalDelegate:nil, didEndSelector:nil, contextInfo:nil)
    else
      performValidation
    end
  end
  
  def validateSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      alert.window.orderOut(self)
      document.saveDocument(self)
      performValidation
    end
  end
  
  def performValidation
    @validationController ||= ValidationController.alloc.init
    if @validationController.validateBook(document, @textViewController.lineNumberView)
      issueViewController.refresh
      showIssueView
    end
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
    when :"toggleIssueView:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = issueViewController.visible? ? "Hide Issues" : "Show Issues"
      end
    when :"toggleInspectorView:"
      if interfaceItem.class == NSMenuItem
        interfaceItem.title = inspectorViewController.visible? ? "Hide Inspector" : "Show Inspector"
      end
    when :"printDocument:"
      @tabViewController.numberOfTabs > 0
    else
      true
    end
  end
  
  private
  
  def shiftFrameOrigin(frame, amount)
    frame.size.height -= amount
    frame.origin.y += amount
  end
  
end