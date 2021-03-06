class PointViewController < NSViewController

  FRAGMENT_POPUP_OFFSET = 2

  attr_reader   :point
  attr_accessor :textField
  attr_accessor :idField
  attr_accessor :sourcePopup
  attr_accessor :fragmentComboBox
  attr_accessor :progressIndicator
  attr_accessor :errorImage
  attr_accessor :popover
  attr_accessor :popoverLabel
  attr_accessor :popoverTextView

  def initWithBookController(controller)
    initWithNibName("PointView", bundle:nil)
    @bookController = controller
    @parsingHash = {}
    @popoverTextAttributes = { 
      NSFontAttributeName => NSFont.systemFontOfSize(11),
      NSForegroundColorAttributeName => NSColor.grayColor
    }
    self
  end
  
  def awakeFromNib
    trackingArea = NSTrackingArea.alloc.initWithRect(@errorImage.bounds, 
        options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow), 
        owner:self, userInfo:nil)
    @errorImage.addTrackingArea(trackingArea)
  end

  def point=(point)
    @point = point
    updateView(@point)
  end

  def updatePoint(sender)
    return unless @point
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
    return unless point
    unless value.blank? || point.text == value
      undoManager.prepareWithInvocationTarget(self).changeText(point, point.text)
      undoManager.actionName = "Change Text"
      point.text = value
    end
    updateView(point)
  end

  def changeID(point, value)
    return unless point
    unless value.blank? || point.id == value
      if oldID = @bookController.document.container.package.navigation.changePointId(point, value)
        undoManager.prepareWithInvocationTarget(self).changeID(point, oldID)
        undoManager.actionName = "Change ID"
      else
        @bookController.runModalAlert("A point with ID \"#{value}\" already exists.", "Please choose a unique point ID.")
      end
    end
    updateView(point)
  end

  def changeSourceAndFragment(point, item, fragment)
    return if point.nil? || point.item == item
    undoManager.prepareWithInvocationTarget(self).changeSourceAndFragment(point, point.item, point.fragment)
    undoManager.actionName = "Change Source"
    point.item = item
    point.fragment = fragment
    @bookController.tabbedViewController.addObject(point)
    updateView(point)
  end

  def changeFragment(point, fragment)
    return if point.nil? || point.fragment == fragment
    if fragment.blank? || point.item.containsFragment?(fragment)
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
    item = @point.item
    if item.fragmentsCached?
      enableFragmentComboBox(item)
      return item.fragments.size
    elsif item.parsingError
      enableFragmentComboBox(item)
      return 0
    else
      disableFragmentComboBox
      Dispatch::Queue.concurrent(:default).async do
        item.fragments
        Dispatch::Queue.main.async do
          enableFragmentComboBox(item)
          @fragmentComboBox.noteNumberOfItemsChanged
          @bookController.tabbedViewController.sourceViewController.updateLineNumberView
        end
      end
      return 0
    end
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
    @bookController.document.container.package.manifest.eachSpineableItem do |item|
      @items << item 
      @sourcePopup.addItemWithTitle(item.href)
    end
    @sourcePopup.selectItemWithTitle(point.href)
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

  def mouseEntered(event)
    if @point && @point.item.parsingError
      string = @point.item.parsingError.chomp
      @popoverTextView.textStorage.attributedString = NSAttributedString.alloc.initWithString(string, attributes:@popoverTextAttributes)
      @popover.showRelativeToRect(@errorImage.bounds, ofView:@errorImage, preferredEdge:NSMaxXEdge)
    end
  end
  
  def enableFragmentComboBox(item)
    @progressIndicator.hidden = true
    @progressIndicator.stopAnimation(self)
    # @fragmentComboBox.enabled = true
    @errorImage.hidden = item.parsingError.nil?
  end
  
  def disableFragmentComboBox
    @progressIndicator.startAnimation(self)
    @progressIndicator.hidden = false
    # @fragmentComboBox.enabled = false
    @errorImage.hidden = true
  end

end