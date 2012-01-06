class PreferencesController < NSWindowController

  FONT_NAME_KEY     = "FontName"
  FONT_SIZE_KEY     = "FontSize"
  STRING_COLOR      = "StringColor"
  TAG_COLOR         = "TagColor"
  COMMENT_COLOR     = "CommentColor"
  KEYWORD_COLOR     = "KeywordColor"
  FOREGROUND_COLOR  = "ForegroundColor"
  BACKGROUND_COLOR  = "BackgroundColor"
  CARET_COLOR       = "CaretColor"
  SELECTION_COLOR   = "SelectionColor"

  attr_reader   :font
  attr_accessor :fontTextField

  attr_reader   :stringColor
  attr_accessor :stringColorWell
  
  attr_reader   :tagColor
  attr_accessor :tagColorWell

  attr_reader   :commentColor
  attr_accessor :commentColorWell

  attr_reader   :keywordColor
  attr_accessor :keywordColorWell

  attr_reader   :foregroundColor
  attr_accessor :foregroundColorWell
  
  attr_reader   :backgroundColor
  attr_accessor :backgroundColorWell
  
  attr_reader   :caretColor
  attr_accessor :caretColorWell

  attr_reader   :selectionColor
  attr_accessor :selectionColorWell

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
    when @keywordColorWell
      @keywordColor = @keywordColorWell.color
    when @foregroundColorWell
      @foregroundColor = @foregroundColorWell.color
    when @backgroundColorWell
      @backgroundColor = @backgroundColorWell.color
    when @caretColorWell
      @caretColor = @caretColorWell.color
    when @selectionColorWell
      @selectionColor = @selectionColorWell.color
    end
    writeColorPreferences
    postNotification
  end
  
  def resetToDefaults(sender)
    @font            = defaultFont
    @stringColor     = defaultStringColor
    @tagColor        = defaultTagColor
    @commentColor    = defaultCommentColor
    @keywordColor    = defaultKeywordColor
    @foregroundColor = defaultForegroundColor
    @backgroundColor = defaultBackgroundColor
    @caretColor      = defaultCaretColor
    @selectionColor  = defaultSelectionColor
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
    @keywordColor    = readColor(KEYWORD_COLOR)    || defaultKeywordColor
    @foregroundColor = readColor(FOREGROUND_COLOR) || defaultForegroundColor
    @backgroundColor = readColor(BACKGROUND_COLOR) || defaultBackgroundColor
    @caretColor      = readColor(CARET_COLOR)      || defaultCaretColor
    @selectionColor  = readColor(SELECTION_COLOR)  || defaultSelectionColor
  end
  
  def writeColorPreferences
    writeColor(@stringColor,     STRING_COLOR)
    writeColor(@tagColor,        TAG_COLOR)
    writeColor(@commentColor,    COMMENT_COLOR)
    writeColor(@keywordColor,    KEYWORD_COLOR)
    writeColor(@foregroundColor, FOREGROUND_COLOR)
    writeColor(@backgroundColor, BACKGROUND_COLOR)
    writeColor(@caretColor,      CARET_COLOR)
    writeColor(@selectionColor,  SELECTION_COLOR)
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
    @keywordColorWell.color    = @keywordColor
    @foregroundColorWell.color = @foregroundColor
    @backgroundColorWell.color = @backgroundColor
    @caretColorWell.color      = @caretColor
    @selectionColorWell.color  = @selectionColor
  end
  
  def defaultFont
    NSFont.userFixedPitchFontOfSize(11.0)
  end
  
  def defaultStringColor
    NSColor.colorWithCalibratedRed(0.86, green:0.07, blue:0.27, alpha:1.0)
  end
  
  def defaultTagColor
    NSColor.colorWithCalibratedRed(0.00, green:0.0, blue:0.50, alpha:1.0)
  end

  def defaultCommentColor
    NSColor.colorWithCalibratedRed(0.60, green:0.60, blue:0.60, alpha:1.0)
  end
  
  def defaultKeywordColor
    NSColor.colorWithCalibratedRed(0.00, green:0.50, blue:0.50, alpha:1.0)
  end

  def defaultForegroundColor
    NSColor.blackColor
  end
  
  def defaultBackgroundColor
    NSColor.whiteColor
  end
  
  def defaultCaretColor
    NSColor.blackColor
  end
  
  def defaultSelectionColor
    NSColor.colorWithCalibratedRed(0.70, green:0.83, blue:0.99, alpha:1.0)
  end
  
  def postNotification
    NSNotificationCenter.defaultCenter.postNotificationName('PreferencesDidChange', object:self)
  end

end