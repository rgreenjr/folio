class MetadataController < NSWindowController
  
  attr_accessor :book
  attr_accessor :titleField, :dateField, :identifierField, :languagePopup
  attr_accessor :descriptionField, :creatorField, :publisherField
  attr_accessor :subjectField, :rightsField, :coverImageView

  def init
    initWithWindowNibName("Metadata")
  end

  def windowDidLoad
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
  end

  def showWindow(sender)
    @titleField.stringValue        = @book.metadata.title || ''
    @descriptionField.stringValue  = @book.metadata.description || ''
    @dateField.stringValue         = @book.metadata.date || ''
    @identifierField.stringValue   = @book.metadata.identifier || ''
    @creatorField.stringValue      = @book.metadata.creator || ''
    @publisherField.stringValue    = @book.metadata.publisher || ''
    @subjectField.stringValue      = @book.metadata.subject || ''
    @rightsField.stringValue       = @book.metadata.rights || ''

    @languagePopup.selectItemWithTitle(Language.name_for(@book.metadata.language))

    if @book.metadata.cover
      @coverImageView.image = NSImage.alloc.initWithContentsOfFile(@book.metadata.cover.path)
    else
      @coverImageView.image = noCoverImage
    end

    window.center
    window.makeKeyAndOrderFront(self)
  end

  def save(sender)
    @book.undoManager.beginUndoGrouping
    changeAttribute("title",       @titleField.stringValue)
    changeAttribute("description", @descriptionField.stringValue)
    changeAttribute("date",        @dateField.stringValue)
    changeAttribute("identifier",  @identifierField.stringValue)    
    changeAttribute("creator",     @creatorField.stringValue)
    changeAttribute("publisher",   @publisherField.stringValue)
    changeAttribute("subject",     @subjectField.stringValue)
    changeAttribute("rights",      @rightsField.stringValue)
    changeAttribute("language",    Language.code_for(@languagePopup.titleOfSelectedItem))
    @book.undoManager.endUndoGrouping
    window.orderOut(self)
  end

  def cancel(sender)
    window.orderOut(self)
  end
  
  private

  def noCoverImage
    @noCoverImage ||= NSImage.imageNamed("no-cover.png")
  end

  def changeAttribute(attribute, value)
    currentValue = @book.metadata.send(attribute)
    return if currentValue == value
    @book.undoManager.prepareWithInvocationTarget(self).changeAttribute(attribute, currentValue)
    @book.undoManager.actionName = "Metadata Change"
    @book.metadata.send("#{attribute}=", value)
  end

end