class PreferencesController < NSWindowController
  
  def init
    initWithWindowNibName("Preferences")
  end

  def showWindow
    window.center
    window.orderFront(self)
  end
  
  
  def showGeneralPane(sender)
  end

end
