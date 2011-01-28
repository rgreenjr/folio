class ItemViewController < NSViewController

  attr_accessor :item, :nameField, :idField, :mediaTypePopup
  
  def initWithBookController(bookController)
    initWithNibName("ItemView", bundle:nil)
    @bookController = bookController
    self
  end
  
  def loadView
    super
    # configure media types popup button
    Media.types.each {|type| @mediaTypePopup.addItemWithTitle(type)}
  end
  
  def item=(item)
    @item = item
    updateView
  end

  def updateItem(sender)
    if sender == @nameField
      changeName(@item, @nameField.stringValue)
    elsif sender == @idField
      changeID(@item, @idField.stringValue)
    else
      changeMediaType(@item, @mediaTypePopup.title)
    end
  end
  
  def changeName(item, value)
    value = value.sanitize
    return if item.name == value
    if item.parent.childWithName(value)
      message = "An item with the name \"#{name}\" already exists in this directory. Please choose a different name."
      Alert.runModal(@bookController.window, message)
    else
      undoManager.prepareWithInvocationTarget(self).changeName(item, item.name)
      undoManager.actionName = "Change Name"
      item.name = value
    end
    updateView
    @bookController.selectionViewController.reloadItem(item)
  end

  # need to go throught @manifest
  def changeID(item, value)
    return if item.id == value
    if oldID = @bookController.document.manifest.changeItemId(item, value)
      undoManager.prepareWithInvocationTarget(self).changeID(item, oldID)
      undoManager.actionName = "Change ID"
    else
      @bookController.runModalAlert("A manifest item with ID \"#{value}\" already exists. Please choose a different ID.")
    end
    updateView
    @bookController.selectionViewController.reloadItem(item)
  end

  def changeMediaType(item, value)
    return if item.mediaType == value
    undoManager.prepareWithInvocationTarget(self).changeMediaType(item, item.mediaType)
    undoManager.actionName = "Change Media Type"
    item.mediaType = value
    updateView
    @bookController.selectionViewController.reloadItem(item)
  end

  private

  def updateView
    if @item
      @nameField.stringValue = @item.name
      @idField.stringValue = @item.id
      @mediaTypePopup.selectItemWithTitle(@item.mediaType)
    end
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end