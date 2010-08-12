class LayoutController
  
  attr_accessor :bookController, :tableView
  
  def book
    @bookController.book
  end
    
  def refresh
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    book ? book.navMap.size : 0
  end
  
  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    book.navMap.navPointAtIndex(index).indentedText
  end
  
  def tableView(aTableView, setObjectValue:value, forTableColumn:column, row:index)
    book.navMap.navPointAtIndex(index).text = value.strip
  end
  
  def tableViewSelectionDidChange(notification)
    @bookController.selectEntryWithHref(book.navMap.navPointAtIndex(tableView.selectedRow).src)
  end

end
