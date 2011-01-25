class SpineController < NSResponder

  attr_accessor :bookController, :outlineView

  def awakeFromNib
    @spine = @bookController.document.spine

    @menu = NSMenu.alloc.initWithTitle("")
    @menu.addActionWithSeparator("Add to Navigation", "addSelectedItemsToNavigation:", self)
    @menu.addAction("Delete", "deleteSelectedItems:", self)
  end

  def numberOfChildrenOfItem(item)
    item == self ? @spine.size : item.size
  end

  def isItemExpandable(item)
    item == self ? true : item.size > 0
  end

  def child(index, ofItem:item)
    item == self ? @spine[index] : item[index]
  end

  def objectValueForTableColumn(tableColumn, byItem:item)
    item == self ? "SPINE" : item.name
  end

  def willDisplayCell(cell, forTableColumn:tableColumn, item:item)
    if item == self
      cell.font = NSFont.boldSystemFontOfSize(11.0)
      cell.image = NSImage.imageNamed('book.png')
      cell.menu = nil
    else
      cell.font = NSFont.systemFontOfSize(11.0)
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
      cell.menu = @menu
    end
  end

  def selectionDidChange(notification)
    if @outlineView.selectedRow >= 0
      @bookController.tabViewController.addObject(@spine[@outlineView.selectedRow])
    end
  end

  def writeItems(items, toPasteboard:pboard)
    itemIds = items.map { |item| item.id }
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(itemIds.to_plist, forType:NSStringPboardType)
    true
  end
  
  def validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
    puts "SpineController.validateDrop"
    NSDragOperationMove
  end
  
  def acceptDrop(info, item:parent, childIndex:childIndex)
    puts "SpineController.acceptDrop"
    itemIds = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    items = []
    newIndexes = []
    offset = 0
    itemIds.reverse.each do |id|
      item = @spine.itemWithId(id)
      items << item
      oldIndex = @spine.index(item)
      if oldIndex < childIndex
        offset += 1
        newIndexes << childIndex - offset
      else
        newIndexes << childIndex
      end
    end
    moveItems(items, newIndexes)
    true
  end
  
  def tableView(tableView, rowForItem:item)
    @spine.index(item)
  end
  
  def addItems(items, indexes=nil)
    indexes ||= Array.new(items.size, -1)
    items.each_with_index do |item, i|
      index = indexes[i]
      @spine.insert(index, item)
    end
    undoManager.prepareWithInvocationTarget(self).deleteItems(items, true)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{pluralize(items.size, "Item")} to Spine"
    end
    reloadDataAndSelectItems(items)
  end

  def selectedItems
    @outlineView.delegate.selectedItemsForController(self)
  end

  def addSelectedItemsToNavigation(sender)
    @bookController.newPointsWithItems(selectedItems)
  end

  def delete(sender)
    deleteSelectedItems(sender)
  end

  def deleteSelectedItems(sender)
    deleteItems(selectedItems)
  end

  def deleteItem(item, allowUndo=true)
    deleteItems([item], allowUndo)
  end

  def deleteItems(items, allowUndo=true)
    return unless items && !items.empty?
    
    # remove any items not included in the spine
    items = items.select { |item| @spine.include?(item) }
    
    indexes = []
    items.each do |item|
      index = @spine.index(item)
      @spine.delete_at(index)
      indexes << index
    end

    if allowUndo
      undoManager.prepareWithInvocationTarget(self).addItems(items.reverse, indexes.reverse)
      unless undoManager.isUndoing
        undoManager.actionName = "Delete #{pluralize(items.size, "Item")} from Spine"
      end
    end

    reloadDataAndSelectItems(nil)
  end

  def moveItems(items, newIndexes)
    oldIndexes = []
    items.each_with_index do |item, index|
      oldIndex = @spine.index(item)
      @spine.delete_at(oldIndex)
      @spine.insert(newIndexes[index], item)
      oldIndexes << oldIndex
    end
    undoManager.prepareWithInvocationTarget(self).moveItems(items.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(items.size, "Item")} in Spine"
    end
    reloadDataAndSelectItems(items)
  end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"addSelectedItemsToNavigation:", :"deleteSelectedItems:", :"delete:"
      @outlineView.numberOfSelectedRows > 0
    else
      true
    end
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

  private

  def reloadDataAndSelectItems(items)
    @outlineView.reloadData
    @outlineView.selectItems(items)
    @bookController.window.makeFirstResponder(@outlineView)
  end

end
