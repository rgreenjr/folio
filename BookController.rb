class BookController

  attr_accessor :window, :book, :layoutController, :spineController, :manifestController

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
    @window.title = @book.title
    @layoutController.layout = @book.layout
    @spineController.spine = @book.spine
    @manifestController.manifest = @book.manifest
  end

  # def tidy(sender)
  #   if @currentItem && @currentItem.tidyable?
  #     @currentItem.tidy
  #   end
  # end

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
