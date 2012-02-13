class PDFController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText

  def init
    initWithWindowNibName("PDFPanel")
  end
  
  def exportBookAsPDF(book)
    savePanel = NSSavePanel.savePanel
    savePanel.prompt = "Export"
    savePanel.nameFieldStringValue = book.container.package.metadata.title
    savePanel.beginSheetModalForWindow(book.controller.window, completionHandler:Proc.new {|resultCode|
      if resultCode == NSOKButton
        @destinationURL = savePanel.URL
        puts "savePanel = #{@destinationURL} => #{@destinationURL.pathExtension}"
        @destinationURL = NSURL.fileURLWithPath(@destinationURL.path + ".pdf") unless @destinationURL.pathExtension == "pdf"
        puts "savePanel = #{@destinationURL}"
        generatePDF(book)
      end      
    })    
  end
  
  def generatePDF(book)
    @shouldStop = false
    @pdfDocuments = []
    showProgressWindow(book)
    @itemQueue = book.container.package.spine.map { |itemref| itemref.item }
    @progressIncrement = 100.0 / @itemQueue.size
    renderNextQueueItem
  end
  
  private
  
  def method_name
    Alert.runModal(@bookController.window, ".", "Please choose a unique item name.")
  end
  
  def renderNextQueueItem
    return if operationCanceled?
    @currentItem = @itemQueue.shift
    if @currentItem
      incrementStatus("Rendering \"#{@currentItem.name}\"...", @progressIncrement)
      renderItem(@currentItem)
    else
      pdf = mergeDocuments(@pdfDocuments)
      puts "pdf = #{pdf}"
      puts "writing to #{@destinationURL.path}"
      pdf.dataRepresentation.writeToURL(@destinationURL, atomically:true)      
      cleanUp
    end
  end
  
  def renderItem(item)    
    return if operationCanceled?
    
    # create a dummy frame far offscreen
    frameRect = [-16000.0, -16000.0, 100, 100]
    
    # create a webView to render the content
    webView = WebView.alloc.initWithFrame(frameRect, frameName:nil, groupName:nil)
    
    # register callback to be notified when webView has completed rendering
    webView.frameLoadDelegate = self

    # create a window to hold the webView
    printWindow = NSWindow.alloc.initWithContentRect(frameRect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreNonretained, defer:false, screen:nil)
    
    # add the webView to the window
    printWindow.contentView.addSubview(webView)
    
    # create a web request
    request = NSURLRequest.requestWithURL(item.url)
    
    # load the page into the webview    
    webView.mainFrame.loadRequest(request, baseURL:nil)
  end
  
  def webView(webView, didFinishLoadForFrame:frame)    
    return if operationCanceled?
    
    # get the documentView from the webView; this view contains the rendered content
    documentView = webView.mainFrame.frameView.documentView
    
    # order the window front and display it (far offscreen)
    documentView.window.orderFront(self)
    documentView.window.display
    
    # lockFocus focus so print operation will take rendered view as content
    documentView.lockFocus

    # print the rendered view
    # printView(documentView)
    
    saveViewAsPDF(documentView)
    
    # release focus lock
    documentView.unlockFocus
    
    # hide window
    documentView.window.orderOut(self)
  end

  def saveViewAsPDF(view)    
    return if operationCanceled?  
    # get sharedPrintInfo and copy its default properties
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
      unless doc
        cleanUp
        puts "problem..."
        raise StandardError, "An error occurred while generating PDF for \"#{@currentItem.name}\"." unless doc
      end
      @pdfDocuments << doc
      renderNextQueueItem
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
  
  def mergeDocuments(pdfDocuments)    
    return if operationCanceled?
    mergedDocument = PDFDocument.alloc.init
    pdfDocuments.each do |pdf|
      return if operationCanceled?
      incrementStatus("Merging rendered files...", @progressIncrement)
      i = 0
      while i < pdf.pageCount
        return if operationCanceled?
        page = pdf.pageAtIndex(i)
        mergedDocument.insertPage(page, atIndex:mergedDocument.pageCount)
        i += 1
      end
    end
    mergedDocument
  end
  
  def showProgressWindow(book)
    Dispatch::Queue.main.async do
      updateStatus("Preparing PDF generation...", 0)
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
    end
  end

  def updateStatus(status, amount)
    Dispatch::Queue.main.async do
      @progressText.stringValue = status
      @progressBar.doubleValue = @progressIncrement
    end
  end
  
  def incrementStatus(status, amount)
    Dispatch::Queue.main.async do
      @progressText.stringValue = status
      @progressBar.incrementBy(@progressIncrement)
    end
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