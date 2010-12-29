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
    if panel.runModalForDirectory(nil, file:nil, types:['epub']) == NSOKButton
      openBook(panel.filename)
    end
  end

  def openBook(filename)
    @progressController.show("Opening...")
    @book = Book.new(filename)
    @metadataController.book = @book
    @spineController.book = @book
    @manifestController.book = @book
    @navigationController.book = @book
    @searchController.book = @book
    @window.title = @book.metadata.title
    @progressController.hide
    @window.makeKeyAndOrderFront(self)
  rescue Exception => e
    @progressController.hide
    Alert.runModal("Unable to Open Book", exception.message)
  end

  def saveBook(sender)
    @progressController.show("Saving...")
    @book.save
    @progressController.hide
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
    @progressController.show("Validating...")
    result = Validator.validate(@book)
    # puts result
    puts "done"
    @progressController.hide
  end

  def validateUserInterfaceItem(menuItem)
    @book != nil
  end
  
end
