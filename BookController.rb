class BookController
  
  attr_accessor :window, :book, :webView, :textView, :layoutController, :entryController
  
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
    @entryController.refresh
    @layoutController.refresh
    selectEntry(@book.spine.first)
  end
  
  def selectEntryWithHref(href)
    selectEntry(@book.entryWithHref(href))
  end
  
  def selectNavPoint(point)
    return unless point
    @currentEntry = point
    refreshWebView
  end
  
  def selectEntry(entry)
    return unless entry
    @currentEntry = entry
    refreshWebView
    #refreshTextView
    #@tableView.selectRowIndexes(NSIndexSet.indexSetWithIndex(@book.indexForEntry(entry)), byExtendingSelection:false)
  end
    
  def textDidChange(notification)
    @currentEntry.content = textView.textStorage.string
    refreshWebView
  end
  
  def refreshWebView
    if @currentEntry.renderable?
    puts @currentEntry.url
        webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@currentEntry.url)))
      else
        webView.mainFrame.loadHTMLString("", baseURL:nil)
    end
  end
  
  def refreshTextView
    text = (@currentEntry.text?) ? @currentEntry.content : ""
    textView.textStorage.attributedString = NSAttributedString.alloc.initWithString(text)
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
