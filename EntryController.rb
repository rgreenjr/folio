class EntryController

  attr_accessor :bookController, :tableView

  def book
    @bookController.book
  end

  def refresh
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    book ? book.entries.size: 0
  end
  
  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    book.entries[index].name
  end
  
  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow == -1
    @bookController.selectEntry(book.entries[@tableView.selectedRow])
  end
  
end