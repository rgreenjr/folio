class MetadataController < NSWindowController

  attr_accessor :bookController, :imageWell, :coverImageView
  attr_accessor :titleField, :dateField, :identifierField, :languagePopup
  attr_accessor :descriptionField, :creatorField, :sortCreatorField, :publisherField
  attr_accessor :subjectField, :rightsField

  SUBJECTS = ["Biography & Memoir", "Business", "Comedy", "History", "Literature", "Nonfiction", "Science", "Technology", "Travel & Adventure"]

  def initWithBookController(bookController)
    initWithWindowNibName("Metadata")
    @bookController = bookController
    @metadata = @bookController.document.metadata
    self
  end

  def windowDidLoad
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
    @creatorField.delegate = self
    @subjectField.delegate = self
    @imageWell.bookController = @bookController
  end

  # attempt to auto-complete sortCreatorField
  def controlTextDidEndEditing(notification)
    textField = notification.object
    if textField == @creatorField && @sortCreatorField.stringValue.blank?
      @sortCreatorField.stringValue = Metadata.deriveSortCreator(textField.stringValue)
    end
  end

  # attempt to auto-complete subjectField
  def controlTextDidChange(notification)
    
    # skip auto-complete if deletingBackward
    if @deletingBackward
      @deletingBackward = false
      return
    end
    
    textField = notification.object
    value = textField.stringValue    
    if textField == @subjectField && !value.blank?
      match = SUBJECTS.find {|subject| subject.match(/^#{value}/i)}
      if match
        @subjectField.stringValue = match
        @subjectField.currentEditor.setSelectedRange(NSRange.new(value.length, match.length))
      end
    end
  end

  # disable subjectField auto-complete if deleteBackward: 
  def control(control, textView:textView, doCommandBySelector:command) 
    if control == @subjectField && command.to_s == "deleteBackward:"
      @deletingBackward = true
    end
    false
  end

  def showMetadataSheet(sender)
    window # force window load
    displayAttribute('title')
    displayAttribute('description')
    displayAttribute('date')
    displayAttribute('identifier')
    displayAttribute('creator')
    displayAttribute('sortCreator')
    displayAttribute('publisher')
    displayAttribute('subject')
    displayAttribute('rights')
    @languagePopup.selectItemWithTitle(Language.name_for(@metadata.language))
    displayCoverImage
    NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
  end
  
  def saveMetadata(sender)
    closeMetadataSheet(sender)
    changeAttribute('title')
    changeAttribute('description')
    changeAttribute('date')
    changeAttribute('identifier')
    changeAttribute('creator')
    changeAttribute('sortCreator')
    changeAttribute('publisher')
    changeAttribute('subject')
    changeAttribute('rights')
    @metadata.language = Language.code_for(@languagePopup.titleOfSelectedItem)
    changeCoverImage
    @bookController.document.updateChangeCount(NSSaveOperation)
  end
  
  def closeMetadataSheet(sender)
    NSApp.endSheet(window)
    window.orderOut(sender)
  end

  def displayCoverImage
    if @metadata.cover
      @coverImageView.image = NSImage.alloc.initWithContentsOfFile(@metadata.cover.path)
    else
      @coverImageView.image = noCoverImage
    end
    @stashedImagePath = nil
  end

  def	imageWellReceivedImage(sender)
    if @imageWell.imagePath.nil?
      displayCoverImage
    elsif @bookController.document.manifest.itemWithHref(@imageWell.imageName)
      showCoverImageCollisionWarning
    end
  end

  def showCoverImageCollisionWarning
    alert = NSAlert.alloc.init
    alert.messageText = "An image named \"#{@imageWell.imageName}\" already exists. Do you want to replace it?"
    alert.addButtonWithTitle "Replace"
    alert.addButtonWithTitle "Cancel"
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:"coverImageCollisionWarningSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def coverImageCollisionWarningSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      @imageWell.imagePath = nil
    else
      displayCoverImage
    end
  end

  def changeCoverImage
    return unless @imageWell.imagePath
    item = @bookController.document.manifest.itemWithHref(@imageWell.imageName)
    if item
      @bookController.manifestController.deleteItems([item])
    end
    item = @bookController.manifestController.addFile(@imageWell.imagePath)
    if item
      @metadata.cover = item
    end
    displayCoverImage
  end

  def noCoverImage
    @noCoverImage ||= NSImage.imageNamed("no-cover.png")
  end

  def displayAttribute(attribute)
    value = @metadata.send(attribute) || ''
    eval("@#{attribute}Field.stringValue = value")
  end

  def changeAttribute(attribute)
    value = eval("@#{attribute}Field.stringValue")
    @metadata.send("#{attribute}=", value)
  end

end