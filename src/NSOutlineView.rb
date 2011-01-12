class NSOutlineView

  def selectItem(item)
    if item
      selectRow(rowForItem(item))
    else
      deselectAll(nil)
    end
  end

  def selectItems(items)
    deselectAll(nil)
    unless items.empty?
      indexes = NSMutableIndexSet.alloc.init
      items.each do |item| 
        row = rowForItem(item)
        indexes.addIndex(row) if row > 0
      end
      selectRowIndexes(indexes, byExtendingSelection:false)      
      scrollRowToVisible(indexes.firstIndex)
    end
  end

  def expandItems(items)
    unless items.empty?
      items.each { |item| expandItem(item) }
    end
  end

end