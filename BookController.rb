class BookController

  attr_accessor :window, :book, :tableView, :webView, :textView

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

  def book=(book)
    @book = book
    window.title = @book.title
    tableView.reloadData
	# tableView.selectRowIndexes(NSIndexSet.indexSetWithIndex(0), byExtendingSelection:false)
  end

  def numberOfRowsInTableView(aTableView)
    @book ? @book.size: 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @book.entryAt(index).name
  end

  def tableViewSelectionDidChange(aNotification)
    return if tableView.selectedRow == -1
    @currentEntry = @book.entryAt(tableView.selectedRow)
    refreshWebView
    refreshTextView
  end

  def textDidChange(notification)
    @currentEntry.content = textView.textStorage.string
    refreshWebView
  end

  def refreshWebView
    if @currentEntry.renderable?
      webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@currentEntry.url)))
    else
      webView.mainFrame.loadHTMLString("", baseURL:nil)
    end
  end

  def refreshTextView
    if @currentEntry.text?
      attrString = NSAttributedString.alloc.initWithString(@currentEntry.content)
    else
      attrString = NSAttributedString.alloc.initWithString("")
    end
    textView.textStorage.attributedString = attrString
    textView.richText = false
  end
  
  def tidy(sender)
	if @currentEntry && @currentEntry.tidyable?
		@currentEntry.tidy
		refreshWebView
		refreshTextView
	end
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
