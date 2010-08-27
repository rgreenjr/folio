class BookController

  attr_accessor :window, :book, :navigationController, :spineController, :manifestController

  def openBook(sender)
    panel = NSOpenPanel.openPanel
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if (panel.runModalForDirectory(nil, file:nil, types:['epub']) == NSOKButton)
      begin
        self.book = Book.new(panel.filename)
      rescue Exception => e
        showAlert(e)
      end
    end
  end

  def saveBook(sender)
    @book.save("/Users/rgreen/Desktop/")
  end

  def book=(book)
    @book = book
    @navigationController.navigation = @book.navigation
    @spineController.spine = @book.spine
    @manifestController.manifest = @book.manifest
    @window.title = @book.title
  end

  def tidy(sender)
    # @currentItem.tidy if @currentItem && @currentItem.tidyable?
  end

  def showTemporaryDirectory(sender)
    system("open #{@book.base}")
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
