class MetadataController
  
  attr_accessor :book, :window
  attr_accessor :titleField, :dateField, :identifierField, :languagePopup
  attr_accessor :descriptionField, :creatorField, :publisherField
  attr_accessor :subjectField, :sourceField, :rightsField, :coverImageView
  
  def awakeFromNib
    Language.names.each {|name| @languagePopup.addItemWithTitle(name)}
  end
  
  def showWindow(sender)
    @titleField.stringValue  = @book.metadata.title || ''
    @descriptionField.stringValue  = @book.metadata.description || ''
    @dateField.stringValue  = @book.metadata.date || ''
    @identifierField.stringValue  = @book.metadata.identifier || ''
    @creatorField.stringValue  = @book.metadata.creator || ''
    @publisherField.stringValue  = @book.metadata.publisher || ''
    @subjectField.stringValue  = @book.metadata.subject || ''
    @rightsField.stringValue  = @book.metadata.rights || ''
    
    @languagePopup.selectItemWithTitle(Language.name_for(@book.metadata.language))
    
    if @book.metadata.cover
      @coverImageView.image = NSImage.alloc.initWithContentsOfFile(@book.metadata.cover.path)
    else
      @coverImageView.image = nil
    end
    
    @window.center
    @window.makeKeyAndOrderFront(self)
  end
  
  def save(sender)
    @book.metadata.title = @titleField.stringValue
    @book.metadata.description = @descriptionField.stringValue
    @book.metadata.date = @dateField.stringValue
    @book.metadata.identifier = @identifierField.stringValue
    @book.metadata.creator = @creatorField.stringValue
    @book.metadata.publisher = @publisherField.stringValue
    @book.metadata.subject = @subjectField.stringValue
    @book.metadata.rights = @rightsField.stringValue
    @book.metadata.language = Language.code_for(@languagePopup.titleOfSelectedItem)
    @window.orderOut(self)
  end
  
  def cancel(sender)
    @window.orderOut(self)
  end

end