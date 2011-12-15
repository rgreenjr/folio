class SelectionViewController < NSViewController

  attr_accessor :bookController
  attr_accessor :navigationController
  attr_accessor :spineController
  attr_accessor :manifestController
  attr_accessor :outlineView

  def initWithBookController(bookController)
    initWithNibName("SelectionView", bundle:nil)
    @bookController = bookController
    self
  end

  def loadView
    super
    @controllers = [@navigationController, @spineController, @manifestController]

    # assign bookController to each controller
    @controllers.each { |controller| controller.bookController = @bookController }
    
    # add ourself to next responder chain
    @bookController.makeResponder(self)
    
    # add each controller to next repsonder chain
    @controllers.each { |controller| @bookController.makeResponder(controller) }
    
    # use our custom image cell
    @outlineView.tableColumns.first.dataCell = ImageCell.new
    
    # register the drag types we support
    @outlineView.registerForDraggedTypes([Point::PBOARD_TYPE, ItemRef::PBOARD_TYPE, Item::PBOARD_TYPE, NSFilenamesPboardType])

    # set up outlineView to process double-click evetns
    @outlineView.target = self
    @outlineView.doubleAction = :"doubleClickAction:"
  end
  
  def doubleClickAction(sender)
    item = @outlineView.itemAtRow(@outlineView.clickedRow)
    @outlineView.isItemExpanded(item) ? @outlineView.collapseItem(item) : @outlineView.expandItem(item)
  end
  
  def expandNavigation(sender)
    @outlineView.expandItem(@navigationController)    
  end
  
  def expandSpine(sender)
    @outlineView.expandItem(@spineController)    
  end

  def expandManifest(sender)
    @outlineView.expandItem(@manifestController)    
  end
  
  def reloadItem(item)
    @outlineView.reloadItem(item)
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource # guard against SDK bug
    item ? controllerForItem(item).numberOfChildrenOfItem(item) : @controllers.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    isController(item) ? true : controllerForItem(item).isItemExpandable(item)
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? controllerForItem(item).child(index, ofItem:item) : @controllers[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    puts "objectValueForTableColumn item is nil" if item == nil
    controllerForItem(item).objectValueForTableColumn(tableColumn, byItem:item)
  end

  def outlineView(outlineView, shouldSelectItem:item)
    !isController(item) # prevent selection of controllers
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    controllerForItem(item).willDisplayCell(cell, forTableColumn:tableColumn, item:item)
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:item)
    controllerForItem(item).setObjectValue(value, forTableColumn:tableColumn, byItem:item)
  end

  def outlineViewSelectionDidChange(notification)
    if @outlineView.numberOfSelectedRows == 1
      item = @outlineView.itemAtRow(@outlineView.selectedRow)
      @bookController.tabbedViewController.addObject(item)
      updateInspector(item)
    else
      updateInspector(nil)
      # puts "multiple or empty selection"
    end
  end

  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    # get the common controller (if there is one) for the items to be written
    @draggingController = commonControllerForItems(items)

    # only allow dragging if all items come from same controller
    @draggingController ? @draggingController.writeItems(items, toPasteboard:pboard) : false
  end

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    # reject unless there a proposed parent
    return NSDragOperationNone unless parent
    
    # get controller for proposed parent and let it validate the drop
    controllerForItem(parent).validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    controllerForItem(parent).acceptDrop(info, item:parent, childIndex:childIndex)
  end

  def selectedItemsForController(controller)
    @outlineView.selectedItems { |item| controllerForItem(item) == controller }
  end

  private

  def isController(item)
    @outlineView.parentForItem(item) == nil
  end

  def controllerForItem(item)
    while !isController(item)
      item = @outlineView.parentForItem(item)
    end
    item
  end

  def commonControllerForItems(items)
    common = nil
    items.each do |item|
      controller = controllerForItem(item)
      common ||= controller
      return nil if common != controller
    end
    common
  end
  
  def updateInspector(item)
    @bookController.inspectorViewController.displayObject(item)
  end

end