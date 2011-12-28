class PointPanelController < NSWindowController

  attr_accessor :bookController
  attr_accessor :sourcePopup
  attr_accessor :fragmentPopup
  attr_accessor :textField
  attr_accessor :idField

  def initWithBookController(bookController)
    initWithWindowNibName("PointPanel")
    @bookController = bookController
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
    if validPointAttributes?
      closePointCreationSheet(self)
      point = Point.new(selectedSourceItem, @textField.stringValue, @idField.stringValue, selectedFragment)
      @bookController.selectionViewController.navigationController.addPoint(point)      
    end
  end
  
  def sourcePopupDidChange(sender)
    resetFragmentPopup
  end
  
  private
  
  def selectedSourceItem
    @items[@sourcePopup.indexOfSelectedItem]
  end
  
  def selectedFragment
    index = @fragmentPopup.indexOfSelectedItem
    index == 0 ? '' : @fragmentPopup.itemAtIndex(index).title
  end
  
  def resetPanel
    loadItems
    resetSourcePopup
    resetFragmentPopup
    @textField.stringValue = ""
    @idField.stringValue = UUID.create
  end
  
  def loadItems
    @items = []
    @bookController.document.manifest.each do |item|
      @items << item if item.flowable?
    end
  end
  
  def resetSourcePopup
    @sourcePopup.removeAllItems
    @items.each do |item| 
      @sourcePopup.addItemWithTitle(item.name) if item.flowable?
    end
  end
  
  def resetFragmentPopup
    # clear all items except default 'None' item
    while @fragmentPopup.numberOfItems > 1
      @fragmentPopup.removeItemAtIndex(@fragmentPopup.numberOfItems - 1)
    end

    # load fragments for current source item selection
    item = selectedSourceItem
    if item
      item.fragments.each do |frag|
        @fragmentPopup.addItemWithTitle(frag)
      end
    end
  end

  def validPointAttributes?
    valid = false
    if @textField.stringValue.blank?
      Alert.runModal(window, "Point text values cannot be blank.", "Please provide a text value.")
    elsif @idField.stringValue.blank?
      Alert.runModal(window, "Point ID values cannot be blank.", "Please provide an ID value.")
    elsif @bookController.document.navigation.hasPointWithId?(@idField.stringValue)
      Alert.runModal(window, "A point with this ID already exists.", "Please choose a unique point ID.")
    else
      valid = true
    end
    valid
  end

end