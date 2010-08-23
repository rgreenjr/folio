class LayoutController
  
  attr_accessor :bookController, :tableView
  
  def book
    @bookController.book
  end
    
  def refresh
    @tableView.reloadData
  end
  
  # def numberOfRowsInTableView(aTableView)
  #   book ? book.navMap.size : 0
  # end
  # 
  # def tableView(aTableView, objectValueForTableColumn:column, row:index)
  #   book.navMap.navPointAtIndex(index).indentedText
  # end
  # 
  # def tableView(aTableView, setObjectValue:value, forTableColumn:column, row:index)
  #   book.navMap.navPointAtIndex(index).text = value.strip
  # end
  # 
  # def tableViewSelectionDidChange(notification)
  #   return if @tableView.selectedRow == -1
  #   @bookController.selectEntryWithHref(book.navMap.navPointAtIndex(@tableView.selectedRow).src)
  # end

	def awakeFromNib
    @tableView.dataSource = self
	end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    item ? item.size : 1
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item.navPoints[index] : book.navMap.navPoints[0]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.text
  end

end
