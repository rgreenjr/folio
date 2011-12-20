class PreferencesController < NSWindowController

  FONT_NAME_KEY = "FontName"
  FONT_SIZE_KEY = "FontSize"

  attr_accessor :fontTextField
  attr_accessor :font
  
  def self.sharedPreferencesController
    @sharedPreferencesController ||= PreferencesController.alloc.init
  end

  def init
    initWithWindowNibName("Preferences")
    @font = readFontPreference
    self
  end

  def awakeFromNib
    window.delegate = self
    updateFontTextField(@font)
  end

  def showWindow(sender)
    super
    window.center
  end

  def showGeneralPane(sender)
  end

  def showFontPanel(sender)
    fontManager = NSFontManager.sharedFontManager
    fontManager.setSelectedFont(@font, isMultiple:false)
    fontManager.delegate = self
    fontManager.orderFrontFontPanel(sender)
  end

  def changeFont(sender)
    @font = sender.convertFont(@font)
    writeFontPreference(@font)
    updateFontTextField(@font)
  end

  private

  def defaultFont
    NSFont.userFixedPitchFontOfSize(11.0)
  end

  def readFontPreference
    fontName = NSUserDefaults.standardUserDefaults.stringForKey(FONT_NAME_KEY)
    fontSize = NSUserDefaults.standardUserDefaults.floatForKey(FONT_SIZE_KEY)
    NSFont.fontWithName(fontName, size:fontSize) || defaultFont
  end

  def writeFontPreference(font)
    NSUserDefaults.standardUserDefaults.setObject(font.fontName, forKey:FONT_NAME_KEY)
    NSUserDefaults.standardUserDefaults.setFloat(font.pointSize, forKey:FONT_SIZE_KEY)
  end

  def updateFontTextField(font)
    @fontTextField.stringValue = "#{font.displayName} #{font.pointSize.to_i} pt."
    postNotification
  end

  def postNotification
    NSNotificationCenter.defaultCenter.postNotificationName('PreferencesDidChange', object:self)
  end

end
