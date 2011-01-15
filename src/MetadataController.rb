class MetadataController < NSWindowController

  attr_accessor :book, :imageWell, :coverImageView
  attr_accessor :titleField, :dateField, :identifierField, :languagePopup
  attr_accessor :descriptionField, :creatorField, :sortCreatorField, :publisherField
  attr_accessor :subjectField, :rightsField

  def init
    initWithWindowNibName("Metadata")
  end

  def windowDidLoad
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
  end

  def showWindow(sender)
    displayAttribute('title')
    displayAttribute('description')
    displayAttribute('date')
    displayAttribute('identifier')
    displayAttribute('creator')
    displayAttribute('sortCreator')
    displayAttribute('publisher')
    displayAttribute('subject')
    displayAttribute('rights')
    @languagePopup.selectItemWithTitle(Language.name_for(@book.metadata.language))
    displayCoverImage
    window.center
    window.level = NSModalPanelWindowLevel
    window.makeKeyAndOrderFront(self)
  end

  def save(sender)
    changeAttribute('title')
    changeAttribute('description')
    changeAttribute('date')
    changeAttribute('identifier')
    changeAttribute('creator')
    changeAttribute('sortCreator')
    changeAttribute('publisher')
    changeAttribute('subject')
    changeAttribute('rights')
    @book.metadata.language = Language.code_for(@languagePopup.titleOfSelectedItem)
    changeCoverImage
    window.orderOut(self)

    # update document change count so user will be prompted to save book
    NSDocumentController.sharedDocumentController.currentDocument.updateChangeCount(NSSaveOperation)
  end

  private

  def displayCoverImage
    if @book.metadata.cover
      @coverImageView.image = NSImage.alloc.initWithContentsOfFile(@book.metadata.cover.path)
    else
      @coverImageView.image = noCoverImage
    end
    @stashedImagePath = nil
  end

  def	imageWellReceivedImage(sender)
    imagePath = @imageWell.imagePath
    if imagePath.nil?
      displayCoverImage
    elsif @book.manifest.itemWithHref(imagePath.lastPathComponent)
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
    item = @book.manifest.itemWithHref(@stashedImagePath.lastPathComponent)
    @book.controller.manifestController.deleteItems([item]) if item
    item = @book.controller.manifestController.addFile(@stashedImagePath)
    @book.metadata.cover = item if item
    displayCoverImage
  end

  def noCoverImage
    @noCoverImage ||= NSImage.imageNamed("no-cover.png")
  end

  def displayAttribute(attribute)
    value = @book.metadata.send(attribute) || ''
    eval("@#{attribute}Field.stringValue = value")
  end

  def changeAttribute(attribute)
    value = eval("@#{attribute}Field.stringValue")
    @book.metadata.send("#{attribute}=", value)
  end

end