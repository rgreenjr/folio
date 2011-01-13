class Alert
  
  def self.runModal(window, messageText, informativeText='')
    alert = NSAlert.alertWithMessageText(messageText, defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:informativeText)
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
  end

end