class MetadataController < NSWindowController

  attr_reader   :bookController
  attr_accessor :imageWell
  attr_accessor :titleField
  attr_accessor :dateField
  attr_accessor :identifierField
  attr_accessor :languagePopup
  attr_accessor :descriptionField
  attr_accessor :creatorField
  attr_accessor :sortCreatorField
  attr_accessor :publisherField
  attr_accessor :subjectField
  attr_accessor :rightsField

  def initWithBookController(controller)
    initWithWindowNibName("Metadata")
    @bookController = controller
    @metadata = @bookController.document.container.package.metadata
    @noCoverImage = NSImage.imageNamed("no-cover.png")

    # register for manifest item deletion notifications
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"manifestWillDeleteItem:", 
    name:"ManifestWillDeleteItem", object:@bookController.document.container.package.manifest)

    self
  end

  def windowDidLoad
    @imageWell.bookController = @bookController

    # populate language popup
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}

    # configure subjectField for autocompletion
    @subjectField.dataSource = self
    @subjectField.delegate = self
  end

  def numberOfItemsInComboBox(comboBox)
    Subject.subjects.size
  end

  def comboBox(comboBox, objectValueForItemAtIndex:index)
    Subject.subjects[index]
  end

  def comboBox(comboBox, completedString:uncompletedString)
    Subject.closestMatch(uncompletedString)
  end  

  def showMetadataSheet(sender)
    window # force window to load
    displayCoverImage
    displayAttributes
    @languagePopup.selectItemWithTitle(Language.nameForCode(@metadata.language))
    NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
  end

  def saveMetadata(sender)
    closeMetadataSheet(sender)
    updateCoverImage
    updateAttributes
    @metadata.language = Language.codeForName(@languagePopup.titleOfSelectedItem)
    @bookController.document.updateChangeCount(NSSaveOperation)
  end

  def closeMetadataSheet(sender)
    NSApp.endSheet(window)
    window.orderOut(sender)
  end

  def displayCoverImage
    if @metadata.cover
      @imageWell.image = NSImage.alloc.initWithContentsOfFile(@metadata.cover.absolutePath)
    else
      @imageWell.image = @noCoverImage
    end
    @stashedImagePath = nil
  end

  def	imageWellReceivedImage(sender)
    if @imageWell.imagePath.nil?
      displayCoverImage
    elsif @bookController.document.container.package.manifest.itemWithHref(@imageWell.imageName)
      showCoverImageCollisionWarning
    end
  end

  def showCoverImageCollisionWarning
    alert = NSAlert.alloc.init
    alert.messageText = "An image named \"#{@imageWell.imageName}\" already exists. Do you want to replace it?"
    alert.informativeText = "You cannot undo this action."
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

  def clearCoverImage(sender)
    @imageWell.image = @noCoverImage
  end

  def manifestWillDeleteItem(notification)
    item = notification.userInfo
    if item && @metadata.cover == item
      @metadata.cover = nil 
    end
  end

  private

  def attributes
    %w{title description date identifier creator sortCreator publisher subject rights}
  end

  def displayAttributes
    attributes.each { |attribute| displayAttribute(attribute) }
  end

  def displayAttribute(attribute)
    value = @metadata.send(attribute) || ''
    eval("@#{attribute}Field.stringValue = value")
  end

  def updateAttributes
    attributes.each { |attribute| updateAttribute(attribute) }
  end

  def updateAttribute(attribute)
    value = eval("@#{attribute}Field.stringValue")
    @metadata.send("#{attribute}=", value)
  end

  def updateCoverImage
    if @imageWell.image == @noCoverImage
      @metadata.cover = nil
    elsif @imageWell.imagePath
      item = @bookController.document.container.package.manifest.itemWithHref(@imageWell.imageName)
      if item
        @bookController.selectionViewController.manifestController.deleteItems([item])
      end
      item = @bookController.selectionViewController.manifestController.addFile(@imageWell.imagePath)
      if item
        @metadata.cover = item
      end
      displayCoverImage
      NSNotificationCenter.defaultCenter.postNotificationName("MetadataDidChange", object:@metadata, userInfo:nil)
    end
  end

end