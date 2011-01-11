class SpineController < NSViewController

  attr_accessor :tableView, :tabView, :headerView
  
  def init
    initWithNibName("Spine", bundle:nil)
  end

  def awakeFromNib
    menu = NSMenu.alloc.initWithTitle("")
    menu.addActionWithSeparator("Add to Navigation", "addToNavigation:", self)
    menu.addAction("Remove", "removeItem:", self)
    @tableView.menu = menu

    @tableView.delegate = self
    @tableView.dataSource = self
    @tableView.registerForDraggedTypes([NSStringPboardType])

    @headerView.title = "Spine"

    # @fileSearchString = nil
    # NSNotificationCenter.defaultCenter.addObserver(self, selector:"fileSearchTextDidChange:", name:"FileSearchTextDidChange", object:nil)
  end

  def book=(book)
    @book = book
    @tableView.reloadData
  end

  def numberOfRowsInTableView(aTableView)
    return 0 unless @tableView.dataSource && @book # guard against SDK bug
    @book.spine ? @book.spine.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @book.spine[index].name
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    @tabView.add(@book.spine[@tableView.selectedRow])
  end

  def tableView(tableView, writeRowsWithIndexes:indexes, toPasteboard:pboard)
    pboard.declareTypes([NSStringPboardType], owner:self)
    array = indexes.inject([]) { |array, index| array << index }
    pboard.setPropertyList(array.to_plist, forType:NSStringPboardType)
    true
  end

  def tableView(tableView, validateDrop:info, proposedRow:row, proposedDropOperation:operation)
    row ? NSDragOperationMove : NSDragOperationNone
  end

  def tableView(tableView, acceptDrop:info, row:rowIndex, dropOperation:operation)
    hash = {}
    plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    plist.reverse_each do |index|
      rowIndex -= 1 if index < rowIndex
      hash[index] = rowIndex
    end
    moveItems(hash)
    true
  end
  
  # TODO fix method
  def appendItems(items)
    hash = {}
    size = @book.spine.size
    items.each_with_index do |item, index|
      hash[index] = item
    end
    addItems(hash)
  end
  
  def addItems(hash)
    indexes = NSMutableIndexSet.alloc.init
    hash.reverse_each do |index, item|
      next if @book.spine.include?(item)
      @book.spine.insert(index, item)
      indexes.addIndex(index)
    end
    undoManager.prepareWithInvocationTarget(self).removeItemsNow(indexes)
    undoManager.actionName = "Remove #{pluralize(indexes.size, "Item")}"
    @tableView.reloadData
    @tableView.selectRowIndexes(indexes, byExtendingSelection:false)
    postChangeNotification
  end
  
  def removeItem(sender)
    removeItemsNow(@tableView.selectedRowIndexes)
  end
  
  def moveItems(hash)
    reversedHash = {}
    hash.reverse_each { |fromIndex, toIndex| reversedHash[toIndex] = fromIndex }
    undoManager.prepareWithInvocationTarget(self).moveItems(reversedHash)
    undoManager.actionName = "Move #{pluralize(hash.size, "Item")}"
    indexes = NSMutableIndexSet.alloc.init
    hash.each do |fromIndex, toIndex|
      item = @book.spine.delete_at(fromIndex)
      @book.spine.insert(toIndex, item)
      indexes.addIndex(toIndex)
    end
    @tableView.reloadData
    @tableView.selectRowIndexes(indexes, byExtendingSelection:false)
    postChangeNotification
  end
  
  def removeItemsNow(indexes)
    hash = {}
    indexes.reverse_each do |index|
      item = @book.spine.delete_at(index)
      @tabView.remove(item)
      hash[index] = item
    end
    undoManager.prepareWithInvocationTarget(self).addItems(hash)
    undoManager.actionName = "Remove #{pluralize(hash.size, "Item")}"
    @tableView.reloadData
    @tableView.deselectAll(nil)
    postChangeNotification
  end
  
  def addToNavigation(sender)
    items = @tableView.selectedRowIndexes.map { |index| @book.spine[index] }
    @book.controller.newPointsFromItems(items)
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"addToNavigation:"
      return false if @tableView.numberOfSelectedRows < 1
    when :"removeItem:"
      return false if @tableView.numberOfSelectedRows < 1
    end
    true
  end

  def postChangeNotification
    NSDocumentController.sharedDocumentController.currentDocument.updateChangeCount(NSSaveOperation)
    NSNotificationCenter.defaultCenter.postNotificationName("SpineDidChange", object:self)
  end

  def undoManager
    @undoManager ||= @tableView.window.undoManager
  end
  
  # def fileSearchTextDidChange(notification)
  #   @fileSearchString = notification.object
  #   @tableView.reloadData
  # end

end