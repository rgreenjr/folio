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
 
end