class BookController

  attr_accessor :book, :window
  attr_accessor :navigationController, :spineController, :manifestController, :metadataController
  attr_accessor :searchController, :progressController, :tabView

  def awakeFromNib
    @window.center
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
    showErrorAlert(e)
  end

  def saveBook(sender)
    @progressController.show("Saving...")
    @book.save("/Users/rgreen/Desktop/")
    @progressController.hide
  end

  def closeBook(sender)
    editedItems = @tabView.editedItems
    unless editedItems.empty?
      title = "You have #{pluralize(editedItems.size, "document")} with unsaved changes in \"#{@book.metadata.title}\". Do you want to save these changes before quiting?"
      message = "Your changes will be lost if you don't save them."
      response = NSRunAlertPanel(title, message, "Save Changes", "Discard Changes", "Cancel")
      case response
      when NSAlertDefaultReturn
        editedItems.each { |item| item.save }
      when NSAlertOtherReturn
        return false
      end        
    end
    @book.close
    true
  end

  def showTemporaryDirectory(sender)
    system("open #{@book.path}")
  end

  private

  def showErrorAlert(exception)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "Unable to Open Book"
    alert.informativeText = exception.message
    alert.runModal
  end

end
