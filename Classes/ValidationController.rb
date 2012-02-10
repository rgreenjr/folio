class ValidationController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText
  attr_accessor :successWindow

  def init
    initWithWindowNibName("Validation")
  end
  
  def validateBook(book, lineNumberView)
    @shouldStop = false
    book.clearIssues    
    showProgressWindow(book)
    
    updateStatus("Checking manifest", 0)

    increment = 75.0 / book.manifest.size
    book.manifest.each do |item|
      if @shouldStop
        hideProgressWindow
        return
      end 
      incrementStatus("Checking item \"#{item.name}\"", increment)
      item.valid?
    end

    increment = 10.0 / book.navigation.size
    book.navigation.each(true) do |point|
      if @shouldStop
        hideProgressWindow
        return
      end 
      incrementStatus("Checking point \"#{point.text}\"", increment)
      point.valid?
    end

    if @shouldStop
      hideProgressWindow
      return
    end 
    updateStatus("Checking manifest", 86)
    book.validateManifest

    if @shouldStop
      hideProgressWindow
      return
    end 
    updateStatus("Checking OPF file", 88)
    book.validateOPF

    if @shouldStop
      hideProgressWindow
      return
    end 
    updateStatus("Checking container", 90)
    book.validateContainer
    
    if @shouldStop
      hideProgressWindow
      return
    end 
    updateStatus("Checking metadata", 95)
    book.validateMetadata
    
    if @shouldStop
      hideProgressWindow
      return
    end 
    updateStatus("Checking navigation", 99)
    book.validateNavigation

    updateStatus("Complete", 100)
    
    hideProgressWindow
    
    if book.totalIssueCount == 0
      showSuccessWindow(book)
    end
  end
  
  def cancelValidation(sender)
    @shouldStop = true
  end
  
  private
  
  def updateStatus(status, amount)
    Dispatch::Queue.main.async do
      @progressText.stringValue = status
      @progressBar.doubleValue = amount
    end
  end
  
  def incrementStatus(status, amount)
    Dispatch::Queue.main.async do
      @progressText.stringValue = status
      @progressBar.incrementBy(amount)
    end
  end
  
  def showProgressWindow(book)
    Dispatch::Queue.main.async do
      window # force window to load
      NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
      @progressBar.startAnimation(self)
    end
  end
  
  def hideProgressWindow
    Dispatch::Queue.main.async do
      NSApp.endSheet(window)
      window.orderOut(self)
      @progressBar.stopAnimation(self)
      updateStatus("", 0)
    end
  end

  def showSuccessWindow(book)
    Dispatch::Queue.main.async do
      NSApp.beginSheet(successWindow, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
      performSelector(:hideSuccessWindow, withObject:nil, afterDelay:2.0)      
    end
  end
  
  def hideSuccessWindow
    NSApp.endSheet(successWindow)
    successWindow.orderOut(nil)
  end

end
