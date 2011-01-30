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
    window.delegate = self
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
    fontManager.setSelectedFont(@editorFont, isMultiple:false)
    fontManager.delegate = self
    fontManager.orderFrontFontPanel(sender)
  end

  def changeFont(sender)
    @editorFont = sender.convertFont(@editorFont)
    updateFontTextField
  end

  def windowDidBecomeKey(notification)
    document = NSDocumentController.sharedDocumentController.currentDocument
    document.controller.tabViewController.toggleCloseMenuKeyEquivalents
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
