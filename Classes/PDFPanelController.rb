class PDFPanelController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText

  def init
    initWithWindowNibName("PDFPanel")
  end
  
  def saveBookAsPDF(book)
    @shouldStop = false
    
    @tempfiles = []
    
    showProgressWindow(book)
    
    # @itemQueue = book.container.package.spine.map { |itemref| itemref.item }
    @itemQueue = [book.container.package.spine[5].item]
    
    renderNextQueueItem
    
    # return if receivedCancelation?
  end
  
  private
  
  def renderNextQueueItem
    item = @itemQueue.shift
    if item
      updateStatus("Rendering #{item.name}...", 50)
      renderItem(item)
    else
      pdf = mergePDFs(@tempfiles)
      puts "saving..."
      pdf.dataRepresentation.writeToFile("/Users/rgreen/Desktop/final.pdf", atomically:true)
      hideProgressWindow
    end
  end
  
  def renderItem(item)
    puts "renderItem..."
    
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
    puts "webView.didFinishLoadForFrame..."
    
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
    puts "saveViewAsPDF..."
    
    # get sharedPrintInfo and copy its default properties
    printInfoDict = NSMutableDictionary.dictionaryWithDictionary(NSPrintInfo.sharedPrintInfo.dictionary)

    printInfoDict[NSPrintJobDisposition] = NSPrintSaveJob
    
    tempfile = Tempfile.new("me.folioapp.pdf.")
    
    printInfoDict[NSPrintSavePath] = tempfile.path
    printInfo = NSPrintInfo.alloc.initWithDictionary(printInfoDict)
    printInfo.horizontalPagination = NSAutoPagination
    printInfo.verticalPagination = NSAutoPagination    
    printInfo.verticallyCentered = false
    printOperation = NSPrintOperation.printOperationWithView(view, printInfo:printInfo)
    printOperation.showPanels = false
    printOperation.runOperation
    
    @tempfiles << tempfile

    renderNextQueueItem
  end
  
  def mergePDFs(files)
    # create placeholder for final PDF document
    mergedPDFDocument = PDFDocument.alloc.init

    index = 1
    files.each do |file|
      puts "Loading PDF #{file.path}..."
      url = NSURL.URLWithString(file.path)
      
      puts "url = #{url.path}"
      
      pdf = PDFDocument.alloc.initWithURL(url)
      
      puts "pdf = #{pdf}"
      
      i = 0
      while i < pdf.pageCount
        page = pdf.pageAtIndex(i)
        puts "inserting page #{i} into #{index}"
        mergedPDFDocument.insertPage(page, atIndex:index)
        index += 1
      end
    end
    mergedPDFDocument
  end
  
  def showProgressWindow(book)
    Dispatch::Queue.main.async do
      updateStatus("", 0)
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
      @progressBar.doubleValue = amount
    end
  end
  
  def cancel(sender)
    @shouldStop = true
  end

  def receivedCancelation?
    if @shouldStop
      hideProgressWindow
      true
    else
      false
    end
  end

end