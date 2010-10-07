class SpineController

  attr_accessor :book, :tableView, :tabView

  def awakeFromNib
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
    selectItem(notification.object.selectedItem)
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
    @draggedRow = indexes.firstIndex
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(@draggedRow.to_s, forType:NSStringPboardType)
    true
  end

  def tableView(tableView, validateDrop:info, proposedRow:row, proposedDropOperation:childIndex)
    row ? NSDragOperationMove : NSDragOperationNone
  end

  def tableView(tableView, acceptDrop:info, row:index, dropOperation:operation)
    return false unless @draggedRow
    item = @book.spine.delete_at(@draggedRow.to_i)
    index = @book.spine.size if index > @book.spine.size
    @book.spine.insert(index, item)
    @tableView.reloadData
    selectItem(item)
    @draggedItem = nil
    true
  end

  def selectItem(item)
    if item
      row = @book.spine.index(item)
      if row
        indices = NSIndexSet.indexSetWithIndex(row)
        @tableView.selectRowIndexes(indices, byExtendingSelection:false)
        return
      end
    end
    @tableView.deselectAll(nil)
  end

  def addPage(sender)
    index = @tableView.selectedRow
    index = @book.spine.size if index < 0
    # item = Item.new("file://#{@book.container.root}/NewPage.xhtml", "#{@book.container.base}/NewPage.xhtml", UUID.create, 'application/xhtml+xml')
    item.content = ''
    @book.spine.insert(index, item)
    @tableView.reloadData
  end

end