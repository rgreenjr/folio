class PreferencesController < NSWindowController

  FONT_NAME_KEY          = "FontName"
  FONT_SIZE_KEY          = "FontSize"
  STRING_COLOR           = "StringColor"
  TAG_COLOR              = "TagColor"
  COMMENT_COLOR          = "CommentColor"
  KEYWORD_COLOR          = "KeywordColor"
  FOREGROUND_COLOR       = "ForegroundColor"
  BACKGROUND_COLOR       = "BackgroundColor"
  RULER_BACKGROUND_COLOR = "RulerBackgroundColor"
  LINE_NUMBER_COLOR      = "LineNumberColor"
  CURRENT_LINE_COLOR     = "CurrentLineColor"
  CARET_COLOR            = "CaretColor"
  SELECTION_COLOR        = "SelectionColor"

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
  
  attr_reader   :rulerBackgroundColor
  attr_accessor :rulerBackgroundColorWell
  
  attr_reader   :lineNumberColor
  attr_accessor :lineNumberColorWell
  
  attr_reader   :currentLineColor
  attr_accessor :currentLineColorWell
  
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
    window.center
    super
  end

  def showGeneralPane(sender)
    # puts "showGeneralPane"
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
    when @lineNumberColorWell
      @lineNumberColor = @lineNumberColorWell.color
    when @currentLineColorWell
      @currentLineColor = @currentLineColorWell.color
    when @rulerBackgroundColorWell
      @rulerBackgroundColor = @rulerBackgroundColorWell.color
    when @caretColorWell
      @caretColor = @caretColorWell.color
    when @selectionColorWell
      @selectionColor = @selectionColorWell.color
    end
    writeColorPreferences
    postNotification
  end
  
  def resetToDefaults(sender)
    @font                 = defaultFont
    @stringColor          = defaultStringColor
    @tagColor             = defaultTagColor
    @commentColor         = defaultCommentColor
    @keywordColor         = defaultKeywordColor
    @foregroundColor      = defaultForegroundColor
    @backgroundColor      = defaultBackgroundColor
    @rulerBackgroundColor = defaultRulerBackgroundColor
    @lineNumberColor      = defaultLineNumberColor
    @currentLineColor     = defaultCurrentLineColor
    @caretColor           = defaultCaretColor
    @selectionColor       = defaultSelectionColor
    writeFontPreference
    writeColorPreferences
    updateFontTextField
    updateColorWells
    postNotification
  end

  private

  def readColorPreferences
    @stringColor          = readColor(STRING_COLOR)           || defaultStringColor
    @tagColor             = readColor(TAG_COLOR)              || defaultTagColor
    @commentColor         = readColor(COMMENT_COLOR)          || defaultCommentColor
    @keywordColor         = readColor(KEYWORD_COLOR)          || defaultKeywordColor
    @foregroundColor      = readColor(FOREGROUND_COLOR)       || defaultForegroundColor
    @backgroundColor      = readColor(BACKGROUND_COLOR)       || defaultBackgroundColor
    @lineNumberColor      = readColor(LINE_NUMBER_COLOR)      || defaultLineNumberColor
    @currentLineColor     = readColor(CURRENT_LINE_COLOR)     || defaultCurrentLineColor
    @rulerBackgroundColor = readColor(RULER_BACKGROUND_COLOR) || defaultRulerBackgroundColor
    @caretColor           = readColor(CARET_COLOR)            || defaultCaretColor
    @selectionColor       = readColor(SELECTION_COLOR)        || defaultSelectionColor
  end
  
  def writeColorPreferences
    writeColor(@stringColor,          STRING_COLOR)
    writeColor(@tagColor,             TAG_COLOR)
    writeColor(@commentColor,         COMMENT_COLOR)
    writeColor(@keywordColor,         KEYWORD_COLOR)
    writeColor(@foregroundColor,      FOREGROUND_COLOR)
    writeColor(@backgroundColor,      BACKGROUND_COLOR)
    writeColor(@rulerBackgroundColor, RULER_BACKGROUND_COLOR)
    writeColor(@lineNumberColor,      LINE_NUMBER_COLOR)
    writeColor(@currentLineColor,     CURRENT_LINE_COLOR)
    writeColor(@caretColor,           CARET_COLOR)
    writeColor(@selectionColor,       SELECTION_COLOR)
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
    @stringColorWell.color          = @stringColor
    @tagColorWell.color             = @tagColor
    @commentColorWell.color         = @commentColor
    @keywordColorWell.color         = @keywordColor
    @foregroundColorWell.color      = @foregroundColor
    @backgroundColorWell.color      = @backgroundColor
    @rulerBackgroundColorWell.color = @rulerBackgroundColor
    @lineNumberColorWell.color      = @lineNumberColor
    @currentLineColorWell.color     = @currentLineColor
    @caretColorWell.color           = @caretColor
    @selectionColorWell.color       = @selectionColor
  end
  
  def defaultFont
    NSFont.userFixedPitchFontOfSize(11.0)
  end
  
  def defaultStringColor
    NSColor.colorWithCalibratedRed(0.91, green:0.22, blue:0.17, alpha:1.0)
  end
  
  def defaultTagColor
    NSColor.colorWithCalibratedRed(0.23, green:0.63, blue:0.75, alpha:1.0)
  end

  def defaultCommentColor
    NSColor.colorWithCalibratedRed(0.46, green:0.41, blue:0.60, alpha:1.0)
  end
  
  def defaultKeywordColor
    NSColor.colorWithCalibratedRed(0.78, green:0.48, blue:0.26, alpha:1.0)
  end

  def defaultForegroundColor
    NSColor.colorWithCalibratedRed(0.50, green:0.74, blue:0.32, alpha:1.0)
  end
  
  def defaultBackgroundColor
    NSColor.colorWithCalibratedRed(0.12, green:0.13, blue:0.16, alpha:1.0)
  end
  
  def defaultRulerBackgroundColor
    NSColor.colorWithCalibratedRed(0.10, green:0.10, blue:0.10, alpha:1.0)
  end
  
  def defaultLineNumberColor
    NSColor.lightGrayColor
  end
  
  def defaultCurrentLineColor
    NSColor.colorWithCalibratedRed(0.19, green:0.27, blue:0.41, alpha:1.0)
  end
  
  def defaultCaretColor
    NSColor.whiteColor
  end
  
  def defaultSelectionColor
    NSColor.colorWithCalibratedRed(0.20, green:0.20, blue:0.20, alpha:0.80)
  end
  
  def postNotification
    NSNotificationCenter.defaultCenter.postNotificationName('PreferencesDidChange', object:self)
  end

end