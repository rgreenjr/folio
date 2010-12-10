class NSOutlineView
  
  def selectItem(item)
    if item
      selectRow(rowForItem(item))
    else
      deselectAll(nil)
    end
  end
  
end