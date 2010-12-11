class SpineController

  attr_accessor :book, :tableView, :tabView

  def awakeFromNib
    @menu = NSMenu.alloc.initWithTitle("Spine Contextual Menu")
    @menu.insertItemWithTitle("Add to Navigation", action:"addToNavigation:", keyEquivalent:"", atIndex:0).target = self
    @menu.addItem(NSMenuItem.separatorItem)
    @menu.insertItemWithTitle("Remove", action:"removeItem:", keyEquivalent:"", atIndex:2).target = self
    @tableView.menu = @menu

    @tableView.delegate = self
    @tableView.dataSource = self
    @tableView.registerForDraggedTypes([NSStringPboardType])
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:nil)
  end

  def book=(book)
    @book = book
    @tableView.reloadData
  end

  def tabViewSelectionDidChange(notification)
    # selectItem(notification.object.selectedItem)
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
    reorderedItems = []
    plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    plist.reverse_each do |index|
      reorderedItems << @book.spine.delete_at(index)
      rowIndex -= 1 if index < rowIndex
    end
    reorderedItems.each do |item|
      @book.spine.insert(rowIndex, item)
    end
    @tableView.reloadData
    range = NSRange.new(rowIndex, reorderedItems.size)
    indexes = NSIndexSet.indexSetWithIndexesInRange(range)
    @tableView.selectRowIndexes(indexes, byExtendingSelection:false)
    true
  end

  # def selectItem(item)
  #   @tableView.selectRow(@book.spine.index(item))
  # end
  
  def removeItem(sender)
    @tableView.selectedRowIndexes.reverse_each do |index|
      item = @book.spine.delete_at(index)
      @tabView.remove(item)
    end
    @tableView.reloadData
  end
  
  def addToNavigation(sender)
    @tableView.selectedRowIndexes.each do |index|
      @book.navigation.appendItem(@book.spine[index])
    end
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

end