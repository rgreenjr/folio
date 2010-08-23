class LayoutController
  
  attr_accessor :bookController, :tableView
  
	def awakeFromNib
    @tableView.dataSource = self
	end

  def refresh
    @tableView.reloadData
  end
  
  def outlineView(outlineView, numberOfChildrenOfItem:item)
    item ? item.size : 1
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item.navPoints[index] : @bookController.book.navMap.navPoints[0]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.text
  end

  def showNext
    puts "showNext"
    showAtIndex(tableView.selectedRow + 1)
  end

  def showPrevious
    puts "showPrevious"
    showAtIndex(tableView.selectedRow - 1)
  end
  
  def showAtIndex(row)
    return if row < 0 || row > book.navMap.size
    bookController.selectNavPoint(book.navMap.navPointAtIndex(row))  
  end

end
