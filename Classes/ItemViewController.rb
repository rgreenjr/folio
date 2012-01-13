class ItemViewController < NSViewController

  attr_accessor :item
  attr_accessor :nameField
  attr_accessor :idField
  attr_accessor :mediaTypeComboBox
  
  def initWithBookController(controller)
    initWithNibName("ItemView", bundle:nil)
    @bookController = controller
    self
  end
  
  def loadView
    super
  end
  
  def item=(item)
    @item = item
    updateView(@item)
  end
  
  def comboBox(comboBox, objectValueForItemAtIndex:index)
    Media.types[index]
  end
  
  def numberOfItemsInComboBox(comboBox)
    Media.types.size
  end
  
  def comboBox(comboBox, completedString:uncompletedString)  
    Media.closestType(uncompletedString)
  end  
  
  def updateItem(sender)
    if sender == @nameField
      changeName(@item, @nameField.stringValue)
    elsif sender == @idField
      changeID(@item, @idField.stringValue)
    else
      changeMediaType(@item, @mediaTypeComboBox.stringValue)
    end
  end
  
  def changeName(item, value)
    unless value.blank? || item.name == value
      value = value.sanitize
      if item.parent.childWithName(value)
        Alert.runModal(@bookController.window, "An item with the name \"#{value}\" already exists in this directory.", "Please choose a unique item name.")
      else
        undoManager.prepareWithInvocationTarget(self).changeName(item, item.name)
        undoManager.actionName = "Change Name"
        item.name = value
      end
    end
    updateView(item)
  end

  def changeID(item, value)
    unless value.blank? || item.id == value
      if oldID = @bookController.document.manifest.changeItemId(item, value)
        undoManager.prepareWithInvocationTarget(self).changeID(item, oldID)
        undoManager.actionName = "Change ID"
      else
        @bookController.runModalAlert("A manifest item with ID \"#{value}\" already exists.", "Please choose a unique item ID.")
      end
    end
    updateView(item)
  end

  def changeMediaType(item, value)
    unless value.blank? || item.mediaType == value
      undoManager.prepareWithInvocationTarget(self).changeMediaType(item, item.mediaType)
      undoManager.actionName = "Change Media Type"
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
        @mediaTypeComboBox.stringValue = ''
        @mediaTypeComboBox.enabled = false
      else
        @idField.stringValue = item.id
        @idField.enabled = true
        @mediaTypeComboBox.stringValue = item.mediaType
        @mediaTypeComboBox.enabled = true
      end
      @bookController.selectionViewController.reloadItem(item)
    end
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end