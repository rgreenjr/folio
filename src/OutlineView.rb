class NSOutlineView

  def selectItem(item)
    if item
      selectRow(rowForItem(item))
    else
      deselectAll(nil)
    end
  end

  def selectItems(array)
    deselectAll(nil)
    unless array.empty?
      indexes = NSMutableIndexSet.alloc.init
      array.each do |item| 
        row = rowForItem(item)
        indexes.addIndex(row) if row > 0
      end
      selectRowIndexes(indexes, byExtendingSelection:false)      
      scrollRowToVisible(indexes.firstIndex)
    end
  end

end