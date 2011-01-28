class PointViewController < NSViewController
  
  attr_accessor :point, :textField, :idField, :sourceField
  
  def initWithBookController(bookController)
    initWithNibName("PointView", bundle:nil)
    @bookController = bookController
    self
  end

  def point=(point)
    @point = point
    updateView
  end
  
  def updatePoint(sender)
    value = sender.stringValue
    if sender == @textField
      changeText(@point, value)
    elsif sender == @idField
      changeID(@point, value)
    else
      changeSource(@point, value)
    end
  end
  
  def changeText(point, value)
    return if point.text == value
    undoManager.prepareWithInvocationTarget(self).changeText(point, point.text)
    undoManager.actionName = "Change Text"
    point.text = value
    updateView
    @bookController.selectionViewController.reloadItem(point)
  end
  
  def changeID(point, value)
    return if point.id == value
    if oldID = @bookController.document.navigation.changePointId(point, value)
      undoManager.prepareWithInvocationTarget(self).changeID(point, oldID)
      undoManager.actionName = "Change ID"
    else
      @bookController.runModalAlert("A point with ID \"#{value}\" already exists. Please choose a different ID.")
    end
    updateView
    @bookController.selectionViewController.reloadItem(point)
  end
  
  def changeSource(point, value)
    return if point.src == value
    href, fragment = value.split('#')
    item = @bookController.document.manifest.itemWithHref(href)
    if item
      undoManager.prepareWithInvocationTarget(self).changeSource(point, point.src)
      undoManager.actionName = "Change Source"
      point.item = item
      point.fragment = fragment
    else
      @bookController.runModalAlert("The manifest doesn't contain \"#{value}\".")
    end
    updateView
    @bookController.tabViewController.addObject(point)
    @bookController.selectionViewController.reloadItem(point)
  end

  private
  
  def updateView
    if @point
      @textField.stringValue = @point.text
      @idField.stringValue = @point.id
      @sourceField.stringValue = @point.src
    end
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end
  
end