class NSOutlineView
  
  # Returns an array containing the items currently selected in the NSOutlineView.
  # If a block is passed, the array will contain only those items for which 
  # block is not false.
  def selectedItems(&block)
    selectedRowIndexes.inject([]) do |array, row| 
      item = itemAtRow(row)
      if block_given?
        array << item if yield(item)
      else
        array << item
      end
      array
    end
  end

  def selectItems(items)
    deselectAll(nil)
    unless items.empty?
      indexes = NSMutableIndexSet.alloc.init
      items.each do |item|
        row = rowForItem(item)
        indexes.addIndex(row) if row >= 0
      end
      selectRowIndexes(indexes, byExtendingSelection:true)      
    end
  end

  def expandItems(items)
    items.each { |item| expandItem(item) } if items
  end

  def scrollItemsToVisible(items)
    scrollRowToVisible(rowForItem(items.first)) if items && !items.empty?
  end

end
