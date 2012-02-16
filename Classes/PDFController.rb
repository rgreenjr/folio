class PDFController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :statusText
  attr_accessor :doneButton
  attr_accessor :cancelButton
  attr_accessor :showInFinderButton

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
        Dispatch::Queue.concurrent.async { generatePDF }
      end      
    })    
  end
  
  def windowDidLoad
    # have progressBar use a separate thread since webView.loadRequest must happen in main GUI thread   
    @progressBar.usesThreadedAnimation = true
  end
  
  def showInFinder(sender)
    NSWorkspace.sharedWorkspace.selectFile(@destinationURL.path, inFileViewerRootedAtPath:nil)
    cleanUp
  end
  
  def done(sender)
    cleanUp
  end

  private
  
  def generatePDF
    @shouldStop = false
    @pdfDocuments = []
    showProgressWindow
    @renderQueue = @bookController.document.container.package.spine.map { |itemref| itemref.item }
    @progressIncrement = 95.0 / @renderQueue.size
    renderNextQueueItem
  end
  
  def renderNextQueueItem
    return if operationCanceled?
    @currentItem = @renderQueue.shift
    if @currentItem
      incrementProgress("Rendering \"#{@currentItem.name}\"...", @progressIncrement)
      Dispatch::Queue.main.async do
        # must execute webView calls in the main GUI thread
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
    
    # create a dummy frame far offscreen; dimensions are 8.5x11 at 72 DPI
    frameRect = [-16000.0, -16000.0, 612, 792]
    
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
      
      doc = PDFDocument.alloc.initWithURL(NSURL.URLWithString("file://#{tempfile.path}"))
      if doc
        @pdfDocuments << doc
      else
        @shouldStop = true
        Alert.runModal(nil, "An unrecoverable error occurred while rendering \"#{@currentItem.name}\".")
      end
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
  
  def mergeDocuments(pdfDocuments)
    return if operationCanceled?
    incrementProgress("Merging rendered files...", 0)
    mergedDocument = PDFDocument.alloc.init
    mergedDocument.documentAttributes = {
      PDFDocumentTitleAttribute   => @bookController.document.container.package.metadata.title,
      PDFDocumentAuthorAttribute  => @bookController.document.container.package.metadata.creator,
      PDFDocumentSubjectAttribute => @bookController.document.container.package.metadata.subject,
      PDFDocumentCreatorAttribute => "Folio"
    }
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
    saveMergedDocument(mergedDocument)
  end

  def saveMergedDocument(pdfDocument)
    @cancelButton.enabled = false
    incrementProgress("Saving PDF document...", 0)
    error = Pointer.new(:id)
    if pdfDocument.dataRepresentation.writeToURL(@destinationURL, options:NSDataWritingAtomic, error:error)
      showExportComplete
    else
      message = "An error occurred while saving \"#{@destinationURL.lastPathComponent}\"."
      Alert.runModal(nil, message, error[0].localizedDescription)
      cleanUp
    end
  end
  
  def showProgressWindow
    Dispatch::Queue.main.async do
      @cancelButton.enabled = true
      @cancelButton.hidden = false
      @doneButton.hidden = true
      @showInFinderButton.hidden = true
      updateProgress("Preparing PDF generation...", 0)
      NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, 
          didEndSelector:nil, contextInfo:nil)
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
    @statusText.stringValue = status
    @progressBar.doubleValue = amount
  end
  
  def incrementProgress(status, amount)
    @statusText.stringValue = status
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
  
  def showExportComplete
    Dispatch::Queue.main.async do
      @progressBar.stopAnimation(self)
      updateProgress("Complete", 100)
      @doneButton.hidden = false
      @showInFinderButton.hidden = false
      @cancelButton.hidden = true
    end
  end
  
end