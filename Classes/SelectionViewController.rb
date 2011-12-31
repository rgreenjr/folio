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

    # display clicked rows and expand/collapse double clicked rows
    @outlineView.target = self
    @outlineView.action = "displayCurrentSelection:"
    @outlineView.doubleAction = "toggleRow:"
  end
  
  def toggleRow(sender)
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
    isController?(item) ? true : controllerForItem(item).isItemExpandable(item)
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? controllerForItem(item).child(index, ofItem:item) : @controllers[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    puts "objectValueForTableColumn item is nil" if item == nil
    controllerForItem(item).objectValueForTableColumn(tableColumn, byItem:item)
  end

  def outlineView(outlineView, shouldSelectItem:item)
    !isController?(item) # prevent selection of controllers
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    controllerForItem(item).willDisplayCell(cell, forTableColumn:tableColumn, item:item)
  end
  
  def outlineView(outlineView, shouldEditTableColumn:tableColumn, item:item)
    controllerForItem(item) != @spineController
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:item)
    controllerForItem(item).setObjectValue(value, forTableColumn:tableColumn, byItem:item)
  end

  def outlineViewSelectionDidChange(notification)
    displayCurrentSelection(self)
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
  
  def currentSelection
    item = @outlineView.itemAtRow(@outlineView.selectedRow)
    isController?(item) ? nil : item
  end
  
  def displayCurrentSelection(sender)
    item = currentSelection
    if @outlineView.numberOfSelectedRows == 1 && item
      @bookController.tabbedViewController.addObject(item)
    end
    updateInspector(item)
  end

  def selectedItemsForController(controller)
    @outlineView.selectedItems { |item| controllerForItem(item) == controller }
  end
  
  def scrollSelectedItemsToVisible
    @outlineView.scrollItemToVisible(currentSelection)
  end

  def revealInManifest(sender)
    expandManifest(self)
    @outlineView.selectItem(currentSelection.item, expandParents:true)
  end
  
  def duplicate(sender)
    item = currentSelection
    controller = controllerForItem(item)
    case controller
    when @navigationController
      controller.duplicatePoint(item)
    end
  end
  
  def delete(sender)
    items = @outlineView.selectedItems
    controller = commonControllerForItems(items)
    case controller
    when @navigationController
      controller.deletePoints(items, true, 0)
    when @spineController
      controller.deleteItemRefs(items)
    when @manifestController
      controller.showDeleteSelectedItemsSheet(self)
    end
  end
  
  def validateMenuItem(menuItem)
    case menuItem.action
    when :"revealInManifest:"
      @outlineView.numberOfSelectedRows == 1
    when :"duplicate:"
      @outlineView.numberOfSelectedRows == 1 && controllerForItem(currentSelection) == @navigationController
    when :"delete:"
      selectedItemsHaveCommonController?
    else
      true
    end
  end

  private

  def isController?(item)
    @outlineView.parentForItem(item) == nil
  end

  def controllerForItem(item)
    while !isController?(item)
      item = @outlineView.parentForItem(item)
    end
    item
  end
  
  def selectedItemsHaveCommonController?
    commonControllerForItems(@outlineView.selectedItems) != nil
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