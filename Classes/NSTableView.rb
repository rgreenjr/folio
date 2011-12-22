class NSTableView
  
  def selectItem(item)
    selectItems([item])
  end
  
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
    if row && row > -1 && row < numberOfRows
      selectRowIndexes(NSIndexSet.indexSetWithIndex(row), byExtendingSelection:false)
      scrollRowToVisible(row)
    end
  end
  
end