class PreferencesController < NSWindowController

  attr_accessor :fontTextField, :editorFont
  
  def self.sharedPreferencesController
    @sharedPreferencesController ||= PreferencesController.alloc.init
  end

  def init
    initWithWindowNibName("Preferences")
    @editorFont = NSFont.userFixedPitchFontOfSize(11.0)
    self
  end

  def awakeFromNib
    updateFontTextField
  end

  def showWindow(sender)
    super
    window.center
  end

  def showGeneralPane(sender)
  end

  def showFontPanel(sender)
    fontManager = NSFontManager.sharedFontManager
    fontManager.delegate = self
    fontManager.orderFrontFontPanel(sender)
  end

  def changeFont(sender)
    @editorFont = sender.convertFont(@editorFont)
    updateFontTextField
  end

  private

  def updateFontTextField
    @fontTextField.stringValue = "#{@editorFont.displayName} #{@editorFont.pointSize.to_i} pt."
    postNotification
  end

  def postNotification
    NSNotificationCenter.defaultCenter.postNotificationName('PreferencesDidChange', object:self)
  end

end
