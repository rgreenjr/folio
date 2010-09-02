class BookController

  attr_accessor :book, :window
  attr_accessor :progressWindow, :progressBar, :progressText
  attr_accessor :navigationController, :spineController, :manifestController

  def awakeFromNib
    readBook("/Users/rgreen/Desktop/Folio/data/The Fall of the Roman Empire_ A New History of Rome and the Barbarians.epub")
  end

  def showOpenBookPanel(sender)
    panel = NSOpenPanel.openPanel
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if (panel.runModalForDirectory(nil, file:nil, types:['epub']) == NSOKButton)
      begin
        readBook(panel.filename)
      rescue Exception => e
        showAlert(e)
      end
    end
  end
  
  def readBook(filename)
    showProgressWindow("Opening...")
    @book = Book.new(filename)
    @spineController.spine = @book.spine
    @manifestController.manifest = @book.manifest
    @navigationController.book = @book
    @window.title = @book.title
    # @window.delegate.toggleView(self)
    hideProgressWindow
    @window.makeKeyAndOrderFront(self)
  end
  
  def saveBookAs(sender)
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
    system("open #{@book.base}")
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
