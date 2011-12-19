class ItemViewController < NSViewController

  attr_accessor :item, :nameField, :idField, :mediaTypeField
  
  def initWithBookController(bookController)
    initWithNibName("ItemView", bundle:nil)
    @bookController = bookController
    self
  end
  
  def loadView
    super
    @mediaTypeField.delegate = self # so we receive text edit notificaitons
  end
  
  def item=(item)
    @item = item
    updateView(@item)
  end
  
  # attempt to auto-complete mediaTypeField
  def controlTextDidChange(notification)
    return unless notification.object == @mediaTypeField
    
    # skip auto-complete if deletingBackward
    if @deletingBackward
      @deletingBackward = false
      return
    end

    value = notification.object.stringValue
    if value.blank?
      type = Media.guessType(@item.name.pathExtension)
    else
      type = Media.closestType(value)
    end
    if type
      @mediaTypeField.stringValue = type
      @mediaTypeField.currentEditor.setSelectedRange(NSRange.new(value.length, type.length))
    end
  end

  # disable mediaTypeField auto-complete if deleteBackward: 
  def control(control, textView:textView, doCommandBySelector:command)
    if control == @mediaTypeField && command.to_s == "deleteBackward:" && @mediaTypeField.stringValue.size > 1
      @deletingBackward = true
    end
    false
  end
  
  def updateItem(sender)
    if sender == @nameField
      changeName(@item, @nameField.stringValue)
    elsif sender == @idField
      changeID(@item, @idField.stringValue)
    else
      changeMediaType(@item, @mediaTypeField.stringValue)
    end
  end
  
  def changeName(item, value)
    unless value.blank? || item.name == value
      value = value.sanitize
      if item.parent.childWithName(value)
        Alert.runModal(@bookController.window, "An item with the name \"#{value}\" already exists in this directory.", "Please choose a unique item name.")
      else
        undoManager.prepareWithInvocationTarget(self).changeName(item, item.name)
        undoManager.actionName = "Change Item Name"
        item.name = value
      end
    end
    updateView(item)
  end

  def changeID(item, value)
    unless value.blank? || item.id == value
      if oldID = @bookController.document.manifest.changeItemId(item, value)
        undoManager.prepareWithInvocationTarget(self).changeID(item, oldID)
        undoManager.actionName = "Change Item ID"
      else
        @bookController.runModalAlert("A manifest item with ID \"#{value}\" already exists.", "Please choose a unique item ID.")
      end
    end
    updateView(item)
  end

  def changeMediaType(item, value)
    unless value.blank? || item.mediaType == value
      undoManager.prepareWithInvocationTarget(self).changeMediaType(item, item.mediaType)
      undoManager.actionName = "Change Item Media Type"
      item.mediaType = value
    end
    updateView(item)
  end

  private

  def updateView(item)
    if item
      @nameField.stringValue = item.name
      if item.directory?
        @idField.stringValue = ''
        @idField.enabled = false
        @mediaTypeField.stringValue = ''
        @mediaTypeField.enabled = false
      else
        @idField.stringValue = item.id
        @idField.enabled = true
        @mediaTypeField.stringValue = item.mediaType
        @mediaTypeField.enabled = true
      end
      @bookController.selectionViewController.reloadItem(item)
    end
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end