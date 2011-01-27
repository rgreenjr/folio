class SelectionViewController < NSViewController

  attr_accessor :outlineView, :bookController
  attr_accessor :navigationController, :spineController, :manifestController

  def awakeFromNib
    @controllers = [@navigationController, @spineController, @manifestController]
    @controllers.each { |controller| @bookController.makeResponder(controller) }
    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.registerForDraggedTypes(["NavigationPointsPboardType", "SpineItemRefsPboardType", "ManifestItemsPboardType", NSFilenamesPboardType])
    @outlineView.doubleAction = :"doubleClickAction:"
    @outlineView.target = self
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.reloadData
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
      @bookController.tabViewController.addObject(item)
    else
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
    items = @outlineView.selectedRowIndexes.map { |index| @outlineView.itemAtRow(index) }
    items.select { |item| controllerForItem(item) == controller }
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

end
