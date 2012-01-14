class PointViewController < NSViewController
  
  FRAGMENT_POPUP_OFFSET = 2
  
  attr_accessor :point
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :sourcePopup
  attr_accessor :fragmentPopup
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
      if @fragmentPopup.indexOfSelectedItem < FRAGMENT_POPUP_OFFSET
        changeFragment(@point, '')
      else
        changeFragment(@point, @fragmentPopup.selectedItem.title)
      end
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
    undoManager.prepareWithInvocationTarget(self).changeFragment(point, point.fragment)
    undoManager.actionName = "Change Fragment"
    point.fragment = fragment
    updateView(point)
  end
  
  private
  
  def updateView(point)
    if point
      @textField.stringValue = point.text
      @idField.stringValue = point.id
      updateSourcePopup(point)
      updateFragmentPopup(point)
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

  def updateFragmentPopup(point)
    # clear all but 'None' and separator menu items
    while @fragmentPopup.numberOfItems > FRAGMENT_POPUP_OFFSET
      @fragmentPopup.removeItemAtIndex(@fragmentPopup.numberOfItems - 1)
    end

    @fragmentPopup.enabled = false
    @progressIndicator.startAnimation(self)
    @progressIndicator.hidden = false
    performSelectorOnMainThread(:"loadFragmentsAndUpdate:", withObject:point, waitUntilDone:false)
  end
  
  def loadFragmentsAndUpdate(point)
    fragments = point.item.fragments
    if fragments
      fragments.each do |frag|
        @fragmentPopup.addItemWithTitle(frag)
      end
    else
      puts "Unable to parse source"
    end
    @fragmentPopup.enabled = true
    @progressIndicator.stopAnimation(self)
    @progressIndicator.hidden = true

    if point.fragment.empty?
      @fragmentPopup.selectItemAtIndex(0)
    else
      @fragmentPopup.selectItemWithTitle(point.fragment)
    end
  end
  
  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end
  
end