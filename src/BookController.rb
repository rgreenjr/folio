class BookController < NSWindowController
  
  MINIMUM_WIDTH = 150.0

  attr_accessor :book, :selectionViewController, :metadataController, :progressController, :tabView

  def awakeFromNib
    window.center
    ctr = NSNotificationCenter.defaultCenter
    ctr.addObserver(self, selector:('markBookEdited:'), name:"NavigationDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"SpineDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"ManifestDidChange", object:nil)
    ctr.addObserver(self, selector:('markBookEdited:'), name:"MetadataDidChange", object:nil)
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
      @selectionViewController.book = @book
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
    @selectionViewController.book = nil
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
  
end
