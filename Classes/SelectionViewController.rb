class SelectionViewController < NSViewController

  attr_reader   :bookController
  attr_accessor :navigationController
  attr_accessor :spineController
  attr_accessor :manifestController
  attr_accessor :outlineView

  def initWithBookController(controller)
    initWithNibName("SelectionView", bundle:nil)
    @bookController = controller
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
    
    # register the drag types we support
    @outlineView.registerForDraggedTypes([Point::PBOARD_TYPE, ItemRef::PBOARD_TYPE, Item::PBOARD_TYPE, NSFilenamesPboardType])

    # display clicked rows and expand/collapse double clicked rows
    @outlineView.target = self
    # @outlineView.action = "displayCurrentSelection:"
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
    row = @outlineView.rowForItem(item)
    @outlineView.reloadDataForRowIndexes(NSIndexSet.indexSetWithIndex(row), columnIndexes:NSIndexSet.indexSetWithIndex(0))
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource # guard against SDK bug
    item ? controllerForItem(item).numberOfChildrenOfItem(item) : @controllers.size
  end

  def outlineView(outlineView, viewForTableColumn:tableColumn, item:item)
    controllerForItem(item).outlineView(outlineView, viewForTableColumn:tableColumn, item:item)
  end
  
  def outlineView(outlineView, rowViewForItem:item)
    if isController?(item)
      SectionRowView.alloc.initWithFrame(NSZeroRect)
    else
      MyTableRowView.alloc.initWithFrame(NSZeroRect)
    end
  end

  def outlineView(outlineView, isItemExpandable:item)
    isController?(item) ? true : controllerForItem(item).isItemExpandable(item)
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? controllerForItem(item).child(index, ofItem:item) : @controllers[index]
  end

  def outlineView(outlineView, shouldSelectItem:item)
    !isController?(item)
  end

  def outlineView(outlineView, shouldEditTableColumn:tableColumn, item:item)
    controllerForItem(item) != @spineController
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

  def outlineView(tableView, heightOfRowByItem:item)
    if item.class == Item && item.hasIssues?
      37.0
    elsif isController?(item)
      22.0
    else
      20.0
    end
  end
  
  def outlineView(outlineView, isGroupItem:item)
    isController?(item)
  end

  def menuForSelectedItems
    controller = commonControllerForItems(@outlineView.selectedItems)
    controller ? controller.menu : nil
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
    @bookController.inspectorViewController.inspectedObject = item
  end

  def selectedItemsForController(controller)
    @outlineView.selectedItems { |item| controllerForItem(item) == controller }
  end
  
  def scrollSelectedItemsToVisible
    @outlineView.scrollItemToVisible(currentSelection)
  end

  def revealInManifest(sender)
    item = @bookController.tabbedViewController.selectedItem
    item = currentSelection.item if item.nil? && currentSelection
    if item
      expandManifest(self)
      @outlineView.selectItem(item, expandParents:true)
    end
  end
  
  def selectPreviousItem(sender)
    row = @outlineView.selectedRow
    row = row == -1 ? @outlineView.numberOfRows - 1 : row - 1
    while row >= 0
      item = @outlineView.itemAtRow(row)
      if isController?(item)
        row -= 1
      else
        @outlineView.selectItem(item)
        break
      end
    end
  end
  
  def selectNextItem(sender)
    row = @outlineView.selectedRow
    row = row == -1 ? 0 : row + 1
    while row < @outlineView.numberOfRows
      item = @outlineView.itemAtRow(row)
      if isController?(item)
        row += 1
      else
        @outlineView.selectItem(item)
        break
      end
    end
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
      @outlineView.numberOfSelectedRows == 1 || @bookController.tabbedViewController.numberOfTabs > 0
    when :"duplicate:"
      @outlineView.numberOfSelectedRows == 1 && controllerForItem(currentSelection) == @navigationController
    when :"delete:"
      commonControllerForItems(@outlineView.selectedItems) != nil
    else
      true
    end
  end
  
  def shiftViewVertically(amount)
    rect = view.frame
    rect.size.height -= amount
    rect.origin.y += amount
    view.animator.frame = rect
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