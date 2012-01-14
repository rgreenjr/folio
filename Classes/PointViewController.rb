class PointViewController < NSViewController
  
  FRAGMENT_POPUP_OFFSET = 2
  
  attr_accessor :point
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :sourcePopup
  attr_accessor :fragmentComboBox
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
    if sender == @textField
      changeText(@point, sender.stringValue)
    elsif sender == @idField
      changeID(@point, sender.stringValue)
    elsif sender == @sourcePopup
      changeSourceAndFragment(@point, @items[@sourcePopup.indexOfSelectedItem], '')
    else
      changeFragment(@point, @fragmentComboBox.stringValue)
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
  
  def changeSourceAndFragment(point, item, fragment)
    return if point.item == item
    undoManager.prepareWithInvocationTarget(self).changeSourceAndFragment(point, point.item, point.fragment)
    undoManager.actionName = "Change Source"
    point.item = item
    point.fragment = fragment
    @bookController.tabbedViewController.addObject(point)
    updateView(point)
  end
  
  def changeFragment(point, fragment)
    return if point.fragment == fragment
    if fragment.blank? || point.item.hasFragment?(fragment)
      undoManager.prepareWithInvocationTarget(self).changeFragment(point, point.fragment)
      undoManager.actionName = "Change Fragment"
      point.fragment = fragment
    else
      @bookController.runModalAlert("\"#{point.item.name}\" doesn't contain the fragment \"#{fragment}\".", "You must specify an existing fragment identifier.")
    end
    updateView(point)
  end
  
  def comboBox(comboBox, objectValueForItemAtIndex:index)
    @point.item.fragments[index]
  end
  
  def numberOfItemsInComboBox(comboBox)
    return 0 unless @point
    return @point.item.fragments.size if @point.item.fragmentsCached?
    performSelectorOnMainThread("loadFragments:", withObject:@point, waitUntilDone:false)
    @progressIndicator.startAnimation(self)
    @progressIndicator.hidden = false
    return 0
  end
  
  def comboBox(comboBox, completedString:uncompletedString)
    @point.item.closestFragment(uncompletedString)
  end  
  
  private
  
  def updateView(point)
    if point
      @textField.stringValue = point.text
      @idField.stringValue = point.id
      updateSourcePopup(point)
      @fragmentComboBox.stringValue = point.fragment
      @fragmentComboBox.noteNumberOfItemsChanged
      @bookController.selectionViewController.reloadItem(point)
    end
  end
  
  def updateSourcePopup(point)
    @sourcePopup.removeAllItems
    @items = []
    @bookController.document.manifest.eachFlowableItem do |item|
      @items << item 
      @sourcePopup.addItemWithTitle(item.href)
    end
    @sourcePopup.selectItemWithTitle(point.href)
  end

  def loadFragments(point)
    point.item.fragments # force fragment parsing
    @progressIndicator.hidden = true
    @progressIndicator.stopAnimation(self)
    @fragmentComboBox.noteNumberOfItemsChanged
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end
  
end