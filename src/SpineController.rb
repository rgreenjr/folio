class SpineController < NSViewController

  attr_accessor :bookController, :tableView, :headerView

  def init
    initWithNibName("Spine", bundle:nil)
  end

  def awakeFromNib
    menu = NSMenu.alloc.initWithTitle("")
    menu.addActionWithSeparator("Add to Navigation", "addSelectedItemsToNavigation:", self)
    menu.addAction("Delete", "deleteSelectedItems:", self)
    @tableView.menu = menu
    @tableView.delegate = self
    @tableView.dataSource = self
    @tableView.registerForDraggedTypes([NSStringPboardType])
    @headerView.title = "Spine"
  end

  def book=(book)
    @book = book
    @tableView.reloadData
  end

  def selectedItems
    @tableView.selectedRowIndexes.map { |index| @book.spine[index] }
  end

  def numberOfRowsInTableView(tableView)
    @tableView.dataSource && @book && @book.spine ? @book.spine.size : 0
  end

  def tableView(tableView, objectValueForTableColumn:column, row:index)
    @book.spine[index].name
  end

  def tableViewSelectionDidChange(notification)
    @bookController.tabViewController.addObject(@book.spine[@tableView.selectedRow]) if @tableView.selectedRow >= 0
  end

  def tableView(tableView, writeRowsWithIndexes:indexes, toPasteboard:pboard)
    itemIds = indexes.map { |index| @book.spine[index].id }
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(itemIds.to_plist, forType:NSStringPboardType)
    true
  end

  def tableView(tableView, validateDrop:info, proposedRow:row, proposedDropOperation:operation)
    row ? NSDragOperationMove : NSDragOperationNone
  end

  def tableView(tableView, acceptDrop:info, row:rowIndex, dropOperation:operation)
    itemIds = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    items = itemIds.reverse.map do |id|
      @book.spine.find { |item| item.id == id }
    end
    newIndexes = Array.new(items.size, rowIndex)
    moveItems(items, newIndexes)
    true
  end

  def tableView(tableView, rowForItem:item)
    @book.spine.index(item)
  end

  def addItems(items, indexes=nil)
    indexes ||= Array.new(items.size, -1)
    items.each_with_index do |item, i|
      index = indexes[i]
      @book.spine.insert(index, item)
    end
    undoManager.prepareWithInvocationTarget(self).deleteItems(items)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{pluralize(items.size, "Item")} to Spine"
    end
    reloadDataAndSelectItems(items)
  end

  def addSelectedItemsToNavigation(sender)
    @book.controller.newPointsFromItems(selectedItems)
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
    indexes = []
    items.each do |item|
      index = @book.spine.index(item)
      @book.spine.delete_at(index)
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
      oldIndex = @book.spine.index(item)
      @book.spine.delete_at(oldIndex)
      @book.spine.insert(newIndexes[index], item)
      oldIndexes << oldIndex
    end
    undoManager.prepareWithInvocationTarget(self).moveItems(items.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(items.size, "Item")} in Spine"
    end
    reloadDataAndSelectItems(items)
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"addSelectedItemsToNavigation:", :"deleteSelectedItems:", :"delete:"
      @tableView.numberOfSelectedRows > 0
    else
      true
    end
  end

  def undoManager
    @undoManager ||= @tableView.window.undoManager
  end

  private

  def reloadDataAndSelectItems(items)
    @tableView.reloadData
    @tableView.selectItems(items)
    @bookController.window.makeFirstResponder(@tableView)
  end

end
