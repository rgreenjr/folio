class PreferencesController < NSWindowController
  
  def init
    initWithWindowNibName("Preferences")
  end

  def showWindow(sender)
    super
    window.center
  end
  
  
  def showGeneralPane(sender)
  end

end
