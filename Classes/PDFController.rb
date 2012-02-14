class PDFController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText

  def initWithBookController(controller)
    initWithWindowNibName("PDFPanel")
    @bookController = controller
    self
  end
  
  def exportBookAsPDF
    if @bookController.document.container.package.spine.empty?
      Alert.runModal(@bookController.window, "Empty Spine", "The spine must contain at least one manifest item.")
      return
    end
    window # force window to load
    savePanel = NSSavePanel.savePanel
    savePanel.prompt = "Export"
    savePanel.allowedFileTypes = ["pdf"]
    savePanel.allowsOtherFileTypes = false
    savePanel.nameFieldStringValue = @bookController.document.container.package.metadata.title
    savePanel.beginSheetModalForWindow(@bookController.window, completionHandler:Proc.new {|resultCode|
      if resultCode == NSOKButton
        @destinationURL = savePanel.URL
        Dispatch::Queue.concurrent.async do
          generatePDF
        end
      end      
    })    
  end
  
  private
  
  def generatePDF
    @shouldStop = false
    @pdfDocuments = []
    showProgressWindow
    @renderQueue = @bookController.document.container.package.spine.map { |itemref| itemref.item }
    @progressIncrement = 90.0 / @renderQueue.size
    renderNextQueueItem
  end
  
  def renderNextQueueItem
    return if operationCanceled?
    @currentItem = @renderQueue.shift
    if @currentItem
      incrementProgress("Rendering item \"#{@currentItem.name}\"...", @progressIncrement)
      Dispatch::Queue.main.async do
        # must execute in the main GUI thread
        renderItem(@currentItem)
      end
    else      
      Dispatch::Queue.concurrent.async do
        mergeDocuments(@pdfDocuments)
      end
    end
  end
  
  def renderItem(item)
    return if operationCanceled?
    
    # create a dummy frame far offscreen
    frameRect = [-16000.0, -16000.0, 100, 100]
    
    # create a webView to render the content
    webView = WebView.alloc.initWithFrame(frameRect, frameName:nil, groupName:nil)
    
    # register to be notified when webView has completed rendering; will invoke webView:didFinishLoadForFrame:
    webView.frameLoadDelegate = self

    # create a window to hold the webView
    offscreenWindow = NSWindow.alloc.initWithContentRect(frameRect, styleMask:NSBorderlessWindowMask, 
        backing:NSBackingStoreNonretained, defer:false, screen:nil)
    
    # add the webView to the window
    offscreenWindow.contentView.addSubview(webView)
    
    # load the page into the webview    
    webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(item.url), baseURL:nil)
  end
  
  def webView(webView, didFinishLoadForFrame:frame)    
    return if operationCanceled?
    documentView = webView.mainFrame.frameView.documentView
    documentView.window.orderFront(self)
    documentView.window.display
    documentView.lockFocus
    saveViewAsPDF(documentView)
    documentView.unlockFocus
    documentView.window.orderOut(self)
    renderNextQueueItem
  end

  def saveViewAsPDF(view)    
    return if operationCanceled?  
    printInfoDict = NSMutableDictionary.dictionaryWithDictionary(NSPrintInfo.sharedPrintInfo.dictionary)
    printInfoDict[NSPrintJobDisposition] = NSPrintSaveJob
    tempfile = Tempfile.new("me.folioapp.pdf.")
    begin    
      printInfoDict[NSPrintSavePath] = tempfile.path
      printInfo = NSPrintInfo.alloc.initWithDictionary(printInfoDict)
      printInfo.horizontalPagination = NSAutoPagination
      printInfo.verticalPagination = NSAutoPagination    
      printInfo.verticallyCentered = false
      printOperation = NSPrintOperation.printOperationWithView(view, printInfo:printInfo)
      printOperation.showPanels = false
      printOperation.runOperation
      @pdfDocuments << PDFDocument.alloc.initWithURL(NSURL.URLWithString("file://#{tempfile.path}"))
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
  
  def mergeDocuments(pdfDocuments)
    return if operationCanceled?
    incrementProgress("Merging rendered files...", 0)
    mergedDocument = PDFDocument.alloc.init
    pdfDocuments.each do |pdf|
      return if operationCanceled?
      i = 0
      while i < pdf.pageCount
        return if operationCanceled?
        page = pdf.pageAtIndex(i)
        mergedDocument.insertPage(page, atIndex:mergedDocument.pageCount)
        i += 1
      end
    end
    updateProgress("Saving PDF document...", 99.0)
    mergedDocument.dataRepresentation.writeToURL(@destinationURL, atomically:true)
    cleanUp
  end
  
  def showProgressWindow
    Dispatch::Queue.main.async do
      updateProgress("Preparing PDF generation...", 0)
      NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
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

  def updateProgress(status, amount)
    @progressText.stringValue = status
    @progressBar.doubleValue = amount
  end
  
  def incrementProgress(status, amount)
    @progressText.stringValue = status
    @progressBar.incrementBy(@progressIncrement)
  end
  
  def cancel(sender)
    @shouldStop = true
  end

  def operationCanceled?
    if @shouldStop
      cleanUp
      true
    else
      false
    end
  end
  
  def cleanUp
    hideProgressWindow
    @pdfDocuments = nil
  end
  
end