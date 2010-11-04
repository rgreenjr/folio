class NSTableView
  
  def selectRow(row)
    if row
      selectRowIndexes(NSIndexSet.indexSetWithIndex(row), byExtendingSelection:false)
    else
      deselectAll(nil)
    end
  end
  
end