class BookController

  attr_accessor :book, :window
  attr_accessor :navigationController, :spineController, :manifestController, :searchController, :progressController

  def awakeFromNib
    readBook(Bundle.path("The Fall of the Roman Empire_ A New History of Rome and the Barbarians", "epub"))
  end

  def showOpenBookPanel(sender)
    panel = NSOpenPanel.openPanel
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if (panel.runModalForDirectory(nil, file:nil, types:['epub']) == NSOKButton)
      begin
        readBook(panel.filename)
      rescue Exception => e
        @progressController.hide
        showAlert(e)
      end
    end
  end
  
  def readBook(filename)
    @progressController.show("Opening...")
    @book = Book.new(filename)
    @spineController.book = @book
    @manifestController.book = @book
    @navigationController.book = @book
    @searchController.book = @book
    @window.title = @book.title
    @progressController.hide
    @window.makeKeyAndOrderFront(self)
  end
  
  def saveBook(sender)
    @progressController.show("Saving...")
    @book.save("/Users/rgreen/Desktop/")
    @progressController.hide
  end

  def showTemporaryDirectory(sender)
    system("open #{@book.path}")
  end

  private

  def showAlert(exception)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "Unable to Open Book"
    alert.informativeText = exception.message
    alert.runModal
  end

end
