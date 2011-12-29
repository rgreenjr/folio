class PointPanelController < NSWindowController
  
  FRAGMENT_POPUP_OFFSET = 2

  attr_accessor :bookController
  attr_accessor :sourcePopup
  attr_accessor :fragmentPopup
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :statusField

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
    index < FRAGMENT_POPUP_OFFSET ? '' : @fragmentPopup.itemAtIndex(index).title
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
    # clear all but default 'None' and separator line menu items
    while @fragmentPopup.numberOfItems > FRAGMENT_POPUP_OFFSET
      @fragmentPopup.removeItemAtIndex(@fragmentPopup.numberOfItems - 1)
    end
    item = selectedSourceItem
    if item
      @fragmentPopup.enabled = false
      @statusField.stringValue = "Parsing source fragments..."
      performSelectorOnMainThread(:"loadFragments:", withObject:item, waitUntilDone:false)
    else
      @statusField.stringValue = ""
    end
  end
  
  def loadFragments(item)
    fragments = item.fragments
    if fragments
      @statusField.stringValue = "Source contains #{"fragment".pluralize(fragments.size)}"
      fragments.each do |frag|
        @fragmentPopup.addItemWithTitle(frag)
      end
    else
      @statusField.stringValue = "Unable to list source fragments: a parsing error occurred"
    end
    @fragmentPopup.enabled = true
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