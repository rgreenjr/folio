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
    
    # register for manifest item deletion notifications
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"manifestWillDeleteItem:", 
        name:"ManifestWillDeleteItem", object:@bookController.document.container.package.manifest)
    
    self
  end

  def windowDidLoad
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
    @imageWell.bookController = @bookController
  end
  
  def comboBox(comboBox, objectValueForItemAtIndex:index)
    Metadata.subjects[index]
  end
  
  def numberOfItemsInComboBox(comboBox)
    Metadata.subjects.size
  end
  
  def comboBox(comboBox, completedString:uncompletedString)  
    Metadata.closestSubject(uncompletedString)
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
      @imageWell.image = NSImage.alloc.initWithContentsOfFile(@metadata.cover.absolutePath)
    else
      @imageWell.image = noCoverImage
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
    @imageWell.image = noCoverImage
  end

  def changeCoverImage
    if @imageWell.image == noCoverImage
      @metadata.cover = nil
    else
      return unless @imageWell.imagePath
      item = @bookController.document.container.package.manifest.itemWithHref(@imageWell.imageName)
      if item
        @bookController.selectionViewController.manifestController.deleteItems([item])
      end
      item = @bookController.selectionViewController.manifestController.addFile(@imageWell.imagePath)
      if item
        @metadata.cover = item
      end
      displayCoverImage
    end
    NSNotificationCenter.defaultCenter.postNotificationName("MetadataDidChange", object:@metadata, userInfo:nil)
  end

  def noCoverImage
    @noCoverImage ||= NSImage.imageNamed("no-cover.png")
  end
  
  def manifestWillDeleteItem(notification)
    item = notification.userInfo
    if item && @metadata.cover == item
      @metadata.cover = nil 
    end
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