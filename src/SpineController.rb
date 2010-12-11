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

  def tableView(tableView, validateDrop:info, proposedRow:row, proposedDropOperation:childIndex)
    row ? NSDragOperationMove : NSDragOperationNone
  end

  # TODO fix reordering bug
  def tableView(tableView, acceptDrop:info, row:index, dropOperation:operation)
    load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType)).reverse_each do |indx|
      puts "indx = #{indx}"
      item = @book.spine.delete_at(indx)
      puts "item.name = #{item.name}"
      index = @book.spine.size if index > @book.spine.size
      puts "destination index = #{index}"
      @book.spine.insert(index, item)
    end
    @tableView.reloadData
    @tableView.deselectAll(nil)
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