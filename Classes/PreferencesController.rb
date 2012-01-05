class PreferencesController < NSWindowController

  FONT_NAME_KEY = "FontName"
  FONT_SIZE_KEY = "FontSize"
  
  STRING_COLOR      = "StringColor"
  TAG_COLOR         = "TagColor"
  COMMENT_COLOR     = "CommentColor"
  IDENTIFIER_COLOR  = "IdentifierColor"
  BACKGROUND_COLOR  = "BackgroundColor"

  attr_reader   :font
  attr_accessor :fontTextField

  attr_reader   :stringColor
  attr_accessor :stringColorWell
  
  attr_reader   :tagColor
  attr_accessor :tagColorWell

  attr_reader   :commentColor
  attr_accessor :commentColorWell

  attr_reader   :identifierColor
  attr_accessor :identifierColorWell

  attr_reader   :backgroundColor
  attr_accessor :backgroundColorWell

  def self.sharedPreferencesController
    @sharedPreferencesController ||= PreferencesController.alloc.init
  end

  def init
    initWithWindowNibName("Preferences")
    readFontPreference
    readColorPreferences
    self
  end

  def awakeFromNib
    window.delegate = self
    updateFontTextField
    updateColorWells
  end

  def showWindow(sender)
    super
    window.center
  end

  def showGeneralPane(sender)
    puts "showGeneralPane"
  end

  def showFontPanel(sender)
    fontManager = NSFontManager.sharedFontManager
    fontManager.setSelectedFont(@font, isMultiple:false)
    fontManager.delegate = self
    fontManager.orderFrontFontPanel(sender)
  end

  def changeFont(sender)
    @font = sender.convertFont(@font)
    updateFontTextField
    writeFontPreference
    postNotification
  end
  
  def changeColor(sender)
    case sender
    when @stringColorWell
      @stringColor = @stringColorWell.color
    when @tagColorWell
      @tagColor = @tagColorWell.color
    when @commentColorWell
      @commentColor = @commentColorWell.color
    when @identifierColorWell
      @identifierColor = @identifierColorWell.color
    when @backgroundColorWell
      @backgroundColor = @backgroundColorWell.color
    end
    writeColorPreferences
    postNotification
  end
  
  def resetToDefaults(sender)
    @font            = defaultFont
    @stringColor     = defaultStringColor
    @tagColor        = defaultTagColor
    @commentColor    = defaultCommentColor
    @identifierColor = defaultIdentifierColor
    @backgroundColor = defaultBackgroundColor
    writeFontPreference
    writeColorPreferences
    updateFontTextField
    updateColorWells
    postNotification
  end

  private

  def readColorPreferences
    @stringColor     = readColor(STRING_COLOR)     || defaultStringColor
    @tagColor        = readColor(TAG_COLOR)        || defaultTagColor
    @commentColor    = readColor(COMMENT_COLOR)    || defaultCommentColor
    @identifierColor = readColor(IDENTIFIER_COLOR) || defaultIdentifierColor
    @backgroundColor = readColor(BACKGROUND_COLOR) || defaultBackgroundColor
  end
  
  def writeColorPreferences
    writeColor(@stringColor,     STRING_COLOR)
    writeColor(@tagColor,        TAG_COLOR)
    writeColor(@commentColor,    COMMENT_COLOR)
    writeColor(@identifierColor, IDENTIFIER_COLOR)
    writeColor(@backgroundColor, BACKGROUND_COLOR)
  end

  def readColor(colorKey)
    data = NSUserDefaults.standardUserDefaults.dataForKey(colorKey)
    NSUnarchiver.unarchiveObjectWithData(data) if data
  end

  def writeColor(color, colorKey)
    data = NSArchiver.archivedDataWithRootObject(color)
    NSUserDefaults.standardUserDefaults.setObject(data, forKey:colorKey)
  end

  def readFontPreference
    fontName = NSUserDefaults.standardUserDefaults.stringForKey(FONT_NAME_KEY)
    fontSize = NSUserDefaults.standardUserDefaults.floatForKey(FONT_SIZE_KEY)
    @font = NSFont.fontWithName(fontName, size:fontSize) || defaultFont
  end

  def writeFontPreference
    NSUserDefaults.standardUserDefaults.setObject(@font.fontName, forKey:FONT_NAME_KEY)
    NSUserDefaults.standardUserDefaults.setFloat(@font.pointSize, forKey:FONT_SIZE_KEY)
  end

  def updateFontTextField
    @fontTextField.stringValue = "#{@font.displayName} #{@font.pointSize.to_i} pt."
  end
  
  def updateColorWells
    @stringColorWell.color     = @stringColor
    @tagColorWell.color        = @tagColor
    @commentColorWell.color    = @commentColor
    @identifierColorWell.color = @identifierColor
    @backgroundColorWell.color = @backgroundColor
  end
  
  def defaultFont
    NSFont.userFixedPitchFontOfSize(11.0)
  end
  
  def defaultStringColor
    NSColor.colorWithCalibratedRed(0.63, green:0.01, blue:0.00, alpha:1.0)
  end
  
  def defaultTagColor
    NSColor.colorWithCalibratedRed(0.24, green:0.34, blue:0.52, alpha:1.0)
  end

  def defaultCommentColor
    NSColor.colorWithCalibratedRed(0.60, green:0.60, blue:0.53, alpha:1.0)
  end
  
  def defaultIdentifierColor
    NSColor.colorWithCalibratedRed(0.00, green:0.10, blue:0.49, alpha:1.0)
  end

  def defaultBackgroundColor
    NSColor.whiteColor
  end
  
  def postNotification
    NSNotificationCenter.defaultCenter.postNotificationName('PreferencesDidChange', object:self)
  end

end