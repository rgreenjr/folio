class PointViewController < NSViewController
  
  attr_accessor :point
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :sourceField
  attr_accessor :progressIndicator
  
  def initWithBookController(controller)
    initWithNibName("PointView", bundle:nil)
    @bookController = controller
    self
  end

  def point=(point)
    @point = point
    updateView(@point)
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
    unless value.blank? || point.text == value
      undoManager.prepareWithInvocationTarget(self).changeText(point, point.text)
      undoManager.actionName = "Change Text"
      point.text = value
    end
    updateView(point)
  end
  
  def changeID(point, value)
    unless value.blank? || point.id == value
      if oldID = @bookController.document.navigation.changePointId(point, value)
        undoManager.prepareWithInvocationTarget(self).changeID(point, oldID)
        undoManager.actionName = "Change ID"
      else
        @bookController.runModalAlert("A point with ID \"#{value}\" already exists.", "Please choose a unique point ID.")
      end
    end
    updateView(point)
  end
  
  def changeSource(point, value)
    unless value.blank? || point.src == value
      href, fragment = value.split('#')
      item = @bookController.document.manifest.itemWithHref(href)
      if item
        showProgressIndicator
        if fragment.blank? || item.hasFragment?(fragment)
          undoManager.prepareWithInvocationTarget(self).changeSource(point, point.src)
          undoManager.actionName = "Change Source"
          point.item = item
          point.fragment = fragment
          @bookController.tabbedViewController.addObject(point)
        else
          @bookController.runModalAlert("Item \"#{item.name}\" doesn't contain the fragment \"#{fragment}\".", "You must specify an existing fragment identifier.")
        end
        hideProgressIndicator
      else
        @bookController.runModalAlert("The manifest doesn't contain an item called \"#{value}\".", "You must specify an item present in the manifest.")
      end
    end
    updateView(point)
  end

  private
  
  def updateView(point)
    if point
      @textField.stringValue = point.text
      @idField.stringValue = point.id
      @sourceField.stringValue = point.src
      @bookController.selectionViewController.reloadItem(point)
    end
  end
  
  def showProgressIndicator
    @progressIndicator.hidden = false
    @progressIndicator.usesThreadedAnimation = true
    @progressIndicator.startAnimation(self)
  end
  
  def hideProgressIndicator
    @progressIndicator.hidden = true
    @progressIndicator.stopAnimation(self)
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end
  
end