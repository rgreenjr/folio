class NavigationController

  attr_accessor :navigation, :outlineView, :inspectorForm
  attr_accessor :webViewController, :textViewController

  def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
  end

  def navigation=(navigation)
    @navigation = navigation
    @outlineView.reloadData
    @outlineView.selectColumnIndexes(NSIndexSet.indexSetWithIndex(1), byExtendingSelection:false)
    @outlineView.expandItem(@navigation.root[0])
  end

  def outlineView(outlineView, numberOfChildrenOfItem:point)
    return 0 unless @outlineView.dataSource && @navigation # guard against SDK bug
    point ? point.size : @navigation.root.size
  end

  def outlineView(outlineView, isItemExpandable:point)
    point && point.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:point)
    point ? point[index] : @navigation.root[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:point)
    point.text
  end

  def outlineViewItemDidExpand(notification)
    notification.userInfo['NSObject'].expanded = true
  end

  def outlineViewItemDidCollapse(notification)
    notification.userInfo['NSObject'].expanded = false
  end

  def outlineViewSelectionDidChange(notification)
    return if @outlineView.selectedRow < 0
    point = @navigation[@outlineView.selectedRow]
    @webViewController.item = point
    @textViewController.item = nil

    textCell.stringValue = point.text
    idCell.stringValue = point.id
    sourceCell.stringValue = point.src    
  end

  def outlineView(outlineView, setObjectValue:object, forTableColumn:tableColumn, byItem:point)
    point.text = object
  end

  def outlineView(outlineView, writeItems:points, toPasteboard:pboard)
    puts "writeRowsWithIndexes"
    @draggedItems = points
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(points.first.text, forType:NSStringPboardType)
    true
  end 

  def outlineView(outlineView, validateDrop:info, proposedItem:point, proposedChildIndex:childIndex)
    puts "validateDrop"
    NSDragOperationMove
  end

  def outlineView(outlineView, acceptDrop:info, item:point, childIndex:childIndex)
    return false unless @draggedItems
    puts "acceptDrop"
    @raggedItems = nil
    @outlineView.reloadData
    true
  end

  def changeText(sender)
    updateAttribute('text', textCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeSource(sender)
    updateAttribute('src', sourceCell)
  end

  private

  def updateAttribute(attribuute, cell)
    item = @navigation[@outlineView.selectedRow]
    return unless item
    value = cell.stringValue.strip
    if value.size > 0
      item.send("#{attribuute}=", value)
      @outlineView.needsDisplay = true
    else
      value = item.send(attribuute)
    end
    cell.stringValue = value
  end

  def textCell
    @inspectorForm.cellAtIndex(0)
  end

  def idCell
    @inspectorForm.cellAtIndex(1)
  end

  def sourceCell
    @inspectorForm.cellAtIndex(2)
  end

end
