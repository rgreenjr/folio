class MetadataController < NSWindowController

  attr_accessor :bookController, :imageWell, :coverImageView
  attr_accessor :titleField, :dateField, :identifierField, :languagePopup
  attr_accessor :descriptionField, :creatorField, :sortCreatorField, :publisherField
  attr_accessor :subjectField, :rightsField

  def init
    initWithWindowNibName("Metadata")
  end

  def windowDidLoad
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
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
    @languagePopup.selectItemWithTitle(Language.name_for(metadata.language))
    displayCoverImage
    NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, didEndSelector:"saveMetadata:", contextInfo:nil)
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
    metadata.language = Language.code_for(@languagePopup.titleOfSelectedItem)
    changeCoverImage
    @bookController.document.updateChangeCount(NSSaveOperation)
  end
  
  def closeMetadataSheet(sender)
    NSApp.endSheet(window)
    window.orderOut(sender)
  end

  def metadata
    @bookController.document.metadata
  end

  def displayCoverImage
    if metadata.cover
      @coverImageView.image = NSImage.alloc.initWithContentsOfFile(metadata.cover.path)
    else
      @coverImageView.image = noCoverImage
    end
    @stashedImagePath = nil
  end

  def	imageWellReceivedImage(sender)
    imagePath = @imageWell.imagePath
    if imagePath.nil?
      displayCoverImage
    elsif @bookController.document.manifest.itemWithHref(imagePath.lastPathComponent)
      showCoverImageCollisionWarning(imagePath)
    else
      @stashedImagePath = imagePath
    end
  end

  def showCoverImageCollisionWarning(imagePath)
    alert = NSAlert.alloc.init
    alert.messageText = "An image named \"#{imagePath.lastPathComponent}\" already exists. Do you want to replace it?"
    alert.addButtonWithTitle "Replace"
    alert.addButtonWithTitle "Cancel"
    alert.beginSheetModalForWindow(window, modalDelegate:self, didEndSelector:"coverImageCollisionWarningSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def coverImageCollisionWarningSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      @stashedImagePath = @imageWell.imagePath
    else
      displayCoverImage
    end
  end

  def changeCoverImage
    return unless @stashedImagePath
    item = @bookController.document.manifest.itemWithHref(@stashedImagePath.lastPathComponent)
    @bookController.manifestController.deleteItems([item]) if item
    item = @bookController.manifestController.addFile(@stashedImagePath)
    metadata.cover = item if item
    displayCoverImage
  end

  def noCoverImage
    @noCoverImage ||= NSImage.imageNamed("no-cover.png")
  end

  def displayAttribute(attribute)
    value = metadata.send(attribute) || ''
    eval("@#{attribute}Field.stringValue = value")
  end

  def changeAttribute(attribute)
    value = eval("@#{attribute}Field.stringValue")
    metadata.send("#{attribute}=", value)
  end

end