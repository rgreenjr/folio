class PrintController

  def self.printView(view)
    return unless view
    
    # get the sharedPrintInfo for the application
    printInfo = NSPrintInfo.sharedPrintInfo

    printInfo.horizontallyCentered = false
    printInfo.verticallyCentered = false
    
    # create a new printOperation with the view and run it
    printOperation = NSPrintOperation.printOperationWithView(view, printInfo:printInfo)
    printOperation.showPanels = true
    printOperation.runOperation
  end
  
  # PDFDocument *outputDocument = [[PDFDocument alloc] init];
  # NSUInteger pageIndex = 0;
  # for (PDFDocument *inputDocument in inputDocuments) {
  #     for (PDFPage *page in inputDocument) {
  #         [outputDocument insertPage:page atIndex:pageIndex++];
  #     }
  # }
  
  private
  
  # the methods below are stubs for the coming ability to print all pages in the book via an offscreen window
  
  def self.printItem(item)
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
  
  def self.webView(webView, didFinishLoadForFrame:frame)
    # get the documentView from the webView; this view contains the rendered content
    documentView = webView.mainFrame.frameView.documentView
    
    # order the window front and display it (far offscreen)
    documentView.window.orderFront(self)
    documentView.window.display
    
    # lockFocus focus so print operation will take rendered view as content
    documentView.lockFocus

    # print the rendered view
    printView(documentView)
    
    # release focus lock
    documentView.unlockFocus
    
    # hide window
    documentView.window.orderOut(self)
  end
    
end