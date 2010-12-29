class Alert
  
  def self.runModal(messageText, informativeText)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.runModal
  end
  
end