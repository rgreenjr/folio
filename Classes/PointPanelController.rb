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
    point = Point.new(selectedSourceItem, @textField.stringValue, @idField.stringValue, @fragmentComboBox.stringValue)
    if !point.valid?
      issue = point.issues.first
      Alert.runModal(window, issue.message, issue.informativeText)
    elsif @bookController.document.navigation.hasPointWithId?(point.id)
      Alert.runModal(window, "A point with this ID already exists.", "Please choose a unique point ID.")
    else
      closePointCreationSheet(self)
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
    @progressIndicator.startAnimation(self)
    @progressIndicator.hidden = false
    Dispatch::Queue.concurrent(:default).async do
      item.fragments # force fragment parsing
      Dispatch::Queue.main.async do
        @progressIndicator.hidden = true
        @progressIndicator.stopAnimation(self)
        @fragmentComboBox.noteNumberOfItemsChanged
      end
    end
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
    @bookController.document.manifest.eachSpineableItem do |item|
      @items << item 
      @sourcePopup.addItemWithTitle(item.href)
    end
  end
  
end