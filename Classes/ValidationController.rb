class ValidationController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText
  attr_accessor :successWindow

  def init
    initWithWindowNibName("Validation")
  end
  
  def validateBook(book)
    loadWindow
    @shouldStop = false
    book.clearIssues    
    showProgressWindow(book)

    increment = 75.0 / book.container.package.manifest.size    
    book.container.package.manifest.each do |item|      
      return if validationCanceled?
      incrementStatus("Checking item \"#{item.name}\"", increment)
      item.valid?
    end

    increment = 10.0 / book.container.package.navigation.size
    book.container.package.navigation.each(true) do |point|
      return if validationCanceled?
      incrementStatus("Checking point \"#{point.text}\"", increment)
      point.valid?
    end

    return if validationCanceled?
    updateStatus("Checking container", 86)
    book.validateContainer
    
    return if validationCanceled?
    updateStatus("Checking package", 88)
    book.validatePackage

    return if validationCanceled?    
    updateStatus("Checking manifest", 90)
    book.validateManifest

    return if validationCanceled?
    updateStatus("Checking metadata", 95)
    book.validateMetadata
    
    return if validationCanceled?
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
    @progressText.stringValue = status
    @progressBar.doubleValue = amount
  end
  
  def incrementStatus(status, amount)
    @progressText.stringValue = status
    @progressBar.incrementBy(amount)
  end
  
  def showProgressWindow(book)
    Dispatch::Queue.main.async do
      updateStatus("", 0)
      NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
      @progressBar.startAnimation(self)
    end
  end
  
  def hideProgressWindow
    Dispatch::Queue.main.async do
      NSApp.endSheet(window)
      window.orderOut(self)
      @progressBar.stopAnimation(self)
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

  def validationCanceled?
    if @shouldStop
      hideProgressWindow
      true
    else
      false
    end
  end

end
