class NavigationController

  attr_accessor :navigation, :outlineView, :propertiesForm
  attr_accessor :webViewController, :textViewController

  def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
    disableProperties
  end

  def book=(book)
    @webViewController.item = nil
    @textViewController.item = nil
    @book = book
    @outlineView.reloadData
    @outlineView.expandItem(@book.navigation.root[0], expandChildren:true) # if @book.navigation.root.size > 0
    # @outlineView.selectRowIndexes(NSIndexSet.indexSetWithIndex(0), byExtendingSelection:false)
    disableProperties
  end

  def outlineView(outlineView, numberOfChildrenOfItem:point)
    return 0 unless @outlineView.dataSource && @book # guard against SDK bug
    point ? point.size : @book.navigation.root.size
  end

  def outlineView(outlineView, isItemExpandable:point)
    point && point.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:point)
    point ? point[index] : @book.navigation.root[index]
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
    if @outlineView.selectedRow < 0
      disableProperties
      @webViewController.item = nil
      @textViewController.item = nil
    else
      point = @book.navigation[@outlineView.selectedRow]
      @webViewController.item = point
      @textViewController.item = point
      textCell.stringValue = point.text
      idCell.stringValue = point.id
      sourceCell.stringValue = point.src
      enableProperties
      # point.item.links
    end
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
    point = @book.navigation[@outlineView.selectedRow]
    return unless point
    uri = URI.parse(sourceCell.stringValue)
    item = @book.manifest.itemWithHref(uri.path)
    
    unless item
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle "OK"
      alert.messageText = "Error"
      alert.informativeText = "Source is not valid: #{uri.to_s}"
      alert.runModal
      sourceCell.stringValue = point.src
      return
    end

    point.item = item
    point.fragment = uri.fragment
    @webViewController.item = point
    @textViewController.item = point
  end

  private

  def updateAttribute(attribuute, cell)
    point = @book.navigation[@outlineView.selectedRow]
    return unless point
    point.send("#{attribuute}=", cell.stringValue)
    cell.stringValue = point.send(attribuute)
    @outlineView.needsDisplay = true
  end

  def textCell
    @propertiesForm.cellAtIndex(0)
  end

  def idCell
    @propertiesForm.cellAtIndex(1)
  end

  def sourceCell
    @propertiesForm.cellAtIndex(2)
  end

  def disableProperties
    propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
  end

  def enableProperties
    propertyCells.each {|cell| cell.enabled = true}
  end
  
  def propertyCells
    [textCell, idCell, sourceCell]
  end

end
