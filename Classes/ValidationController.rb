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
    
    updateStatus("Checking manifest", 0)

    increment = 95.0 / book.manifest.size
    book.manifest.each do |item|
      incrementStatus("Checking #{item.name}", increment)
      item.valid?
    end
    book.validateManifest

    updateStatus("Checking OPF file", 96)
    book.validateOPF

    # updateStatus("Checking container", 25)
    # book.validateContainer
    
    updateStatus("Checking metadata", 97)
    book.validateMetadata
    
    updateStatus("Checking navigation", 98)
    book.validateNavigation

    updateStatus("Complete", 100)
    
    hideProgressWindow
    
    if book.totalIssueCount == 0
      showSuccessWindow(book)
    end
  end
  
  private
  
  def updateStatus(status, amount)
    @progressText.stringValue = status
    @progressBar.doubleValue = amount
    sleep 0.01
  end
  
  def incrementStatus(status, amount)
    @progressText.stringValue = status
    @progressBar.incrementBy(amount)
    sleep 0.01
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
