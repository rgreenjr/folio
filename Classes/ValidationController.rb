class ValidationController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText
  attr_accessor :successWindow

  def init
    initWithWindowNibName("Validation")
  end
  
  def validateBook(book, lineNumberView)
    book.clearIssues    
    showProgressWindow(book)
    
    updateStatus("Validating OPF file", 0)
    book.validateOPF

    # updateStatus("Validating container", 25)
    # book.validateContainer
    
    updateStatus("Validating metadata", 50)
    book.validateMetadata

    updateStatus("Validating manifest", 75)
    book.validateManifest
    
    updateStatus("Validating navigation", 90)
    book.validateNavigation

    updateStatus("Complete", 100)
    
    hideProgressWindow
    showSuccessWindow(book) if book.totalIssueCount == 0
  end
  
  private
  
  def updateStatus(status, amount)
    @progressText.stringValue = status
    @progressBar.doubleValue = amount
  end
  
  def showProgressWindow(book)
    window # force window to load
    NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
    window.makeKeyAndOrderFront(nil) # necessary since we're running in a background thread
    @progressBar.usesThreadedAnimation = true
    @progressBar.startAnimation(self)
  end
  
  def hideProgressWindow
    NSApp.endSheet(window)
    window.orderOut(self)
    @progressBar.stopAnimation(self)
    updateStatus("", 0)
  end

  def showSuccessWindow(book)
    NSApp.beginSheet(successWindow, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
    sleep(2)
    performSelectorOnMainThread(:hideSuccessWindow, withObject:nil, waitUntilDone:false)
  end
  
  def hideSuccessWindow
    NSApp.endSheet(successWindow)
    successWindow.orderOut(nil)
  end

end
