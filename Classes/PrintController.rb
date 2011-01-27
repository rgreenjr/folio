class PrintController
  
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
    
    # get the sharedPrintInfo for the application
    printInfo = NSPrintInfo.sharedPrintInfo

    # printInfo.topMargin = 15.0
    # printInfo.leftMargin = 10.0
    # printInfo.horizontallyCentered = false
    # printInfo.verticallyCentered = false
    
    # lockFocus focus so print operation will take rendered view as content
    documentView.lockFocus

    # create a new printOperation with the documentView and run it
    printOperation = NSPrintOperation.printOperationWithView(documentView, printInfo:printInfo)
    printOperation.showPanels = true
    printOperation.runOperation

    # release focus lock
    documentView.unlockFocus
    
    documentView.window.orderOut(self)
  end
  
end