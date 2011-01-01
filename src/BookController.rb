class BookController

  attr_accessor :book, :window
  attr_accessor :navigationController, :spineController, :manifestController, :metadataController
  attr_accessor :searchController, :progressController, :tabView

  def awakeFromNib
    @window.center
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
      assignBookToControllers(@book)
    end
    @window.makeKeyAndOrderFront(self)
  rescue Exception => exception
    Alert.runModal("Unable to Open Book", exception.message)
  end

  def saveBook(sender)
    showProgressWindow("Saving...") { @book.save }
    @book.edited = false
    @window.documentEdited = false
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
    @window.documentEdited = false
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
    assignBookToControllers(nil)
    @tabView.closeAllTabs
    @book.close
    true
  end

  def markBookEdited(notification)
    @book.edited = true
    @window.documentEdited = true
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
    @metadataController.book = book
    @metadataController.window
    @metadataController.showWindow(self)
  end

  def showProgressWindow(title, &block)
    @progressController ||= ProgressController.alloc.init
    @progressController.window
    @progressController.showWindow(title, &block)
  end

  private

  def assignBookToControllers(book)
    @metadataController.book = book if @metadataController
    @spineController.book = book
    @manifestController.book = book
    @navigationController.book = book
    @searchController.book = book
    @window.title = book ? book.metadata.title : ''
  end

end
