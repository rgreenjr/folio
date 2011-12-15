class BookWindowController < NSWindowController

  ISSUE_VIEW_MIN_HEIGHT    = 100.0
  SELECTION_VIEW_MIN_WIDTH = 150.0
  
  attr_accessor :masterSplitView # contains selectionView (left) and contentSplitView (right)
  attr_accessor :selectionView
  attr_accessor :selectionViewController
  attr_accessor :tabbedViewController
  attr_accessor :contentSplitView # contains contentPlaceholder (top) and issueView (bottom)
  attr_accessor :contentPlaceholder # contains either logoImageView or tabbedView
  attr_accessor :logoImageView
  attr_accessor :layoutSegementedControl
  attr_accessor :inspectorButton
  attr_accessor :issueButton

  def init
    initWithWindowNibName("Book")
  end

  def awakeFromNib
    # create tabbedViewController
    @tabbedViewController = TabbedViewController.alloc.initWithBookController(self)
    
    # create selectionViewController
    @selectionViewController = SelectionViewController.alloc.initWithBookController(self)

    # put selectionView in place
    @selectionViewController.view.frame = @selectionView.frame
    @selectionView.addSubview(selectionViewController.view)
    
    # put logoImageView in place
    @logoImageView.frame = @contentPlaceholder.frame
    @logoImageView.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@logoImageView)
    
    # put tabbedView in place
    @tabbedViewController.view.frame = @contentPlaceholder.frame
    @tabbedViewController.view.frameOrigin = NSZeroPoint
    @contentPlaceholder.addSubview(@tabbedViewController.view)
    
    # register for tabView selection change events
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", 
        name:"TabViewSelectionDidChange", object:@tabbedViewController.tabView)

    # force issueView to load
    issueViewController
    
    # show logo in content area by default
    showLogoImage
    
    # expand the navigation tree by default
    @selectionViewController.expandNavigation(self)

    window.makeKeyAndOrderFront(nil)
  end

  def windowTitleForDocumentDisplayName(windowTitleForDocumentDisplayName)
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
    @tabbedViewController.selectedTab ? showTabbedView : showLogoImage
  end
  
  def showTabbedView
    @logoImageView.hidden = true
    @tabbedViewController.show
  end

  def showLogoImage
    @logoImageView.hidden = false
    @tabbedViewController.hide
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

  def showStagingDirectory(sender)
    NSTask.launchedTaskWithLaunchPath("/usr/bin/open", arguments:[document.unzipPath])
  end

  def searchWikipedia(sender)
    openURL("http://en.wikipedia.org/wiki/Special:Search/#{document.metadata.title.urlEscape}")
  end

  def searchGoogle(sender)
    openURL("http://www.google.com/search?q=#{document.metadata.title.urlEscape}+#{document.metadata.creator.urlEscape}")
  end

  def searchAmazon(sender)
    openURL("http://www.amazon.com/s?field-keywords=#{document.metadata.title.urlEscape}+#{document.metadata.creator.urlEscape}")
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
    if @validationController.validateBook(document, @tabbedViewController.textViewController.lineNumberView)
      issueViewController.refresh
      showIssueView
    end
  end
  
  def printDocument(sender)
    PrintController.printView(@tabbedViewController.selectedTabPrintView)
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
      @tabbedViewController.numberOfTabs > 0
    else
      true
    end
  end
  
  private
  
  def openURL(url)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(url))
  end
  
  def shiftFrameOrigin(frame, amount)
    frame.size.height -= amount
    frame.origin.y += amount
  end
  
end