class BookController

  attr_accessor :book, :window
  attr_accessor :progressWindow, :progressBar, :progressText
  attr_accessor :navigationController, :spineController, :manifestController

  def awakeFromNib
    
    # file = '/Users/rgreen/code/ruby/css-parser/test/test1.css'
    # parser = CSSParser.new
    # result = parser.parse(IO.read(file))
    # raise "Failed to parse CSS file: " + parser.failure_reason unless result
    # p parser
    
    path = NSBundle.mainBundle.pathForResource("The Fall of the Roman Empire_ A New History of Rome and the Barbarians", ofType:"epub")
    readBook(path)
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
    @spineController.book = @book
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
