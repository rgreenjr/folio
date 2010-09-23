class BookController

  attr_accessor :book, :window
  attr_accessor :progressWindow, :progressBar, :progressText
  attr_accessor :navigationController, :spineController, :manifestController

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
        hideProgressWindow
        showAlert(e)
      end
    end
  end
  
  def readBook(filename)
    showProgressWindow("Opening...")
    @book = Book.new(filename)
    @spineController.book = @book
    @manifestController.book = @book
    @navigationController.book = @book
    @window.title = @book.title
    hideProgressWindow
    @window.makeKeyAndOrderFront(self)
  end
  
  def saveBook(sender)
    showProgressWindow("Saving...")
    @book.save("/Users/rgreen/Desktop/")
    hideProgressWindow
  end

  def tidy(sender)
    # @currentItem.tidy if @currentItem && @currentItem.tidyable?
  end

  def showTemporaryDirectory(sender)
    system("open #{@book.path}")
  end

  private

  def showProgressWindow(title)
    @progressText.stringValue = title
    @progressWindow.makeKeyAndOrderFront(self)
    @progressBar.usesThreadedAnimation = true
    @progressBar.startAnimation(self)
  end
  
  def hideProgressWindow
    @progressWindow.orderOut(self)
    @progressBar.stopAnimation(self)
  end

  def showAlert(exception)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "Unable to Open Book"
    alert.informativeText = exception.message
    alert.runModal
  end

end
