class SpineController

  attr_accessor :book, :tableView, :tabView

  def awakeFromNib
    # configure popup menu
    @menu = NSMenu.alloc.initWithTitle("Spine Contextual Menu")
    @menu.insertItemWithTitle("Delete", action:"deleteItem:", keyEquivalent:"", atIndex:0).target = self
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
    array = []
    indexes.each { |index| array << index }
    pboard.setPropertyList(array.to_plist, forType:NSStringPboardType)
    true
  end

  def tableView(tableView, validateDrop:info, proposedRow:row, proposedDropOperation:operation)
    row ? NSDragOperationMove : NSDragOperationNone
  end

  def tableView(tableView, acceptDrop:info, row:destinationIndex, dropOperation:operation)
    array = []
    load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType)).reverse_each do |index|
      array << @book.spine.delete_at(index)
      destinationIndex -= 1 if index < destinationIndex
    end
    array.each do |item|
      @book.spine.insert(destinationIndex, item)
    end
    @tableView.reloadData
    range = NSRange.new(destinationIndex, array.size)
    indexes = NSIndexSet.indexSetWithIndexesInRange(range)
    @tableView.selectRowIndexes(indexes, byExtendingSelection:false)
    true
  end

  def selectItem(item)
    @tableView.selectRow(@book.spine.index(item))
  end
  
  def deleteItem(sender)
    @tableView.selectedRowIndexes.reverse_each do |index|
      @book.spine.delete_at(index)
    end
    @tableView.reloadData
  end

end