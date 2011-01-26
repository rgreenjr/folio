class NSOutlineView

  def selectItems(items)
    deselectAll(nil)
    unless items.empty?
      indexes = NSMutableIndexSet.alloc.init
      items.each do |item|
        row = rowForItem(item)
        indexes.addIndex(row) if row > 0
      end
      selectRowIndexes(indexes, byExtendingSelection:true)      
      scrollRowToVisible(indexes.firstIndex)
    end
  end

  def expandItems(items)
    items.each { |item| expandItem(item) } if items
  end

  def expandItems(items)
    items.each { |item| expandItem(item) } if items
  end

end