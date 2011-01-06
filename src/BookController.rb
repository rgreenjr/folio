class BookController < NSWindowController
  
  MINIMUM_WIDTH = 150.0

  attr_accessor :book, :seletionView, :tabView, :segmentedControl

  def awakeFromNib
    window.center
    ctr = NSNotificationCenter.defaultCenter
    ctr.addObserver(self, selector:('markBookEdited:'), name:"NavigationDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"SpineDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"ManifestDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"MetadataDidChange", object:nil)
    showNavigationView(self)
  end

  def showOpenBookPanel(sender)
    panel = NSOpenPanel.openPanel
    panel.title = "Open Book"
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.delegate = self
    if panel.runModalForDirectory(nil, file:nil, types:['epub']) == NSOKButton
      return if @book && !closeBook(nil)
      openBook(panel.filename)
    end
  end

  # runModalForDirectory delegate method
  def panel(sender, shouldEnableURL:url)
    @book.nil? || url.path != @book.filepath # disable selection of current book
  end

  def openBook(filename)
    showProgressWindow("Opening...") do
      @book = Book.new(filename)
      navigationController.book = book if @navigationController
      spineController.book = book if @spineController
      manifestController.book = book if @manifestController
      searchController.book = book if @searchController
      window.title = @book ? @book.metadata.title : ''
    end
    window.makeKeyAndOrderFront(self)
  rescue Exception => exception
    Alert.runModal("Unable to Open Book", exception.message)
  end

  def saveBook(sender)
    showProgressWindow("Saving...") { @book.save }
    @book.edited = false
    window.documentEdited = false
  end

  def showSaveBookAsPanel(sender)
    panel = NSSavePanel.savePanel
    panel.title = "Save Book As..."
    panel.beginSheetForDirectory(File.dirname(@book.filepath), file:File.basename(@book.filepath),
    modalForWindow:@window, modalDelegate:self, didEndSelector:"saveBookAsPanelDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def saveBookAsPanelDidEnd(panel, returnCode:code, contextInfo:info)
    return unless code == NSOKButton
    @book.saveAs(panel.URL.path)
    @book.edited = false
    window.documentEdited = false
  end

  def saveAll(sender)
    tabs = @tabView.editedTabs
    unless tabs.empty?
      tabs.each { |tab| tabView.saveTab(tab) }
      saveBook(nil)
    end
  end

  def closeBook(sender)
    tabs = @tabView.editedTabs
    if @book.edited? || !tabs.empty?
      title = "You have unsaved changes in the book \"#{@book.metadata.title}\". Do you want to save these changes before quiting?"
      message = "Your changes will be lost if you don't save them."
      response = NSRunAlertPanel(title, message, "Save Changes", "Discard Changes", "Cancel")
      case response
      when NSAlertDefaultReturn
        saveAll(nil)
      when NSAlertOtherReturn
        return false
      end
    end
    window.title = ''
    @tabView.closeAllTabs
    @book.close
    true
  end

  def markBookEdited(notification)
    @book.edited = true
    window.documentEdited = true
  end

  def showTemporaryDirectory(sender)
    system("open #{@book.unzippath}")
  end

  def validate(sender)
    showProgressWindow("Validating...") do
      # result = Validator.validate(@book)
      # puts result
    end
  end

  def validateUserInterfaceItem(menuItem)
    @book != nil
  end

  def splitView(sender, constrainMinCoordinate:proposedMin, ofSubviewAt:offset)
    return proposedMin + MINIMUM_WIDTH
  end

  def splitView(sender, constrainMaxCoordinate:proposedMax, ofSubviewAt:offset)
    return proposedMax - MINIMUM_WIDTH
  end

  # keep left split pane from resizing as window resizes
  def splitView(sender, resizeSubviewsWithOldSize:oldSize)
    newFrame = sender.frame
    left = sender.subviews[0]
    leftFrame = left.frame
    right = sender.subviews[1]
    rightFrame = right.frame
    leftFrame.size.height = newFrame.size.height
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - sender.dividerThickness
    rightFrame.size.height = newFrame.size.height
    rightFrame.origin.x = leftFrame.size.width + sender.dividerThickness
    left.setFrame(leftFrame)
    right.setFrame(rightFrame)
  end

  def windowShouldClose(sender)
    NSApp.terminate(sender)
  end
  
  def showMetadataPanel(sender)
    @metadataController ||= MetadataController.alloc.init
    @metadataController.book = @book
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
      @navigationController ||= NavigationController.alloc.init
      @navigationController.loadView
      @navigationController.tabView = @tabView
      @navigationController.book = @book
    end
    @navigationController
  end

  def spineController
    unless @spineController
      @spineController ||= SpineController.alloc.init
      @spineController.loadView
      @spineController.tabView = @tabView
      @spineController.book = @book
    end
    @spineController
  end

  def manifestController
    unless @manifestController
      @manifestController ||= ManifestController.alloc.init
      @manifestController.loadView
      @manifestController.tabView = @tabView
      @manifestController.book = @book
    end
    @manifestController
  end

  def searchController
    unless @searchController
      @searchController ||= SearchController.alloc.init
      @searchController.loadView
      @searchController.tabView = @tabView
      @searchController.book = @book
    end
    @searchController
  end
  
  def showNavigationView(sender)
    changeController(navigationController)
  end

  def showSpineView(sender)
    changeController(spineController)
  end

  def showManifestView(sender)
    changeController(manifestController)
  end

  def showSearchView(sender)
    changeController(searchController)
  end
  
  def showUnregisteredFiles(sender)
    manifestController.showUnregisteredFiles
  end

  private

  def changeController(controller)
    controller.view.frame = @seletionView.frame
    @seletionView.subviews.first.removeFromSuperview unless @seletionView.subviews.empty?
    @seletionView.animator.addSubview(controller.view)
  end
  
end
