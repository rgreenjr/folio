class NSTableView
  
  def selectItems(items)
    deselectAll(nil)
    unless items.empty? || dataSource.nil?
      indexes = NSMutableIndexSet.alloc.init
      items.each do |item| 
        row = dataSource.tableView(self, rowForItem:item)
        indexes.addIndex(row) if row > -1
      end
      selectRowIndexes(indexes, byExtendingSelection:false)      
      scrollRowToVisible(indexes.firstIndex)
    end
  end

  def selectRow(row)
    if row
      selectRowIndexes(NSIndexSet.indexSetWithIndex(row), byExtendingSelection:false)
    else
      deselectAll(nil)
    end
  end
  
end