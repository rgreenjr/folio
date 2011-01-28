class Alert
  
  def self.runModal(window, messageText, informativeText='')
    alert = NSAlert.alloc.init
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
  end

end