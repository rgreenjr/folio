class PointPanelController < NSWindowController
  
  FRAGMENT_POPUP_OFFSET = 2

  attr_reader   :bookController
  attr_accessor :sourcePopup
  attr_accessor :fragmentComboBox
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :progressIndicator

  def initWithBookController(controller)
    initWithWindowNibName("PointPanel")
    @bookController = controller
    self
  end

  def windowDidLoad
    @items = []
  end
  
  def showPointCreationSheet(sender)
    window # force window load
    resetPanel
    NSApp.beginSheet(window, modalForWindow:@bookController.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
  end
  
  def closePointCreationSheet(sender)
    NSApp.endSheet(window)
    window.orderOut(sender)
  end
  
  def createPoint(sender)
    item = selectedSourceItem
    fragment = @fragmentComboBox.stringValue
    text = @textField.stringValue
    identifier = @idField.stringValue
    if validPointAttributes?(item, text, identifier, fragment)
      closePointCreationSheet(self)
      point = Point.new(item, text, identifier, fragment)
      @bookController.selectionViewController.navigationController.addPoint(point)      
    end
  end
  
  def sourcePopupDidChange(sender)
    @fragmentComboBox.noteNumberOfItemsChanged
  end
  
  def comboBox(comboBox, objectValueForItemAtIndex:index)
    selectedSourceItem.fragments[index]
  end
  
  def numberOfItemsInComboBox(comboBox)
    item = selectedSourceItem
    return 0 unless item
    return item.fragments.size if item.fragmentsCached?
    performSelectorOnMainThread("loadFragments:", withObject:item, waitUntilDone:false)
    @progressIndicator.startAnimation(self)
    @progressIndicator.hidden = false
    return 0
  end
  
  def comboBox(comboBox, completedString:uncompletedString)
    selectedSourceItem.closestFragment(uncompletedString)
  end
  
  private
  
  def selectedSourceItem
    @items ? @items[@sourcePopup.indexOfSelectedItem] : nil
  end
  
  def resetPanel
    resetSourcePopup
    @fragmentComboBox.stringValue = ''
    @fragmentComboBox.noteNumberOfItemsChanged
    @textField.stringValue = "New Point"
    @idField.stringValue = UUID.create
  end
  
  def resetSourcePopup
    @sourcePopup.removeAllItems
    @items = []
    @bookController.document.manifest.eachFlowableItem do |item|
      @items << item 
      @sourcePopup.addItemWithTitle(item.href)
    end
  end
  
  def loadFragments(item)
    item.fragments # force fragment parsing
    @progressIndicator.hidden = true
    @progressIndicator.stopAnimation(self)
    @fragmentComboBox.noteNumberOfItemsChanged
  end
  
  def validPointAttributes?(item, text, identifier, fragment)
    valid = false
    if !fragment.blank? && !item.containsFragment?(fragment)
      Alert.runModal(window, "\"#{item.name}\" doesn't contain the fragment \"#{fragment}\".", "You must specify an existing fragment identifier.")
    elsif text.blank?
      Alert.runModal(window, "Point text values cannot be blank.", "Please provide a text value.")
    elsif identifier.blank?
      Alert.runModal(window, "Point ID values cannot be blank.", "Please provide an ID value.")
    elsif @bookController.document.navigation.hasPointWithId?(identifier)
      Alert.runModal(window, "A point with this ID already exists.", "Please choose a unique point ID.")
    else
      valid = true
    end
    valid
  end

end