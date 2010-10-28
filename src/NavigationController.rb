class NavigationController

  attr_accessor :navigation, :outlineView, :propertiesForm, :tabView

  def awakeFromNib
    @menu = NSMenu.alloc.initWithTitle("Navigation Contextual Menu")
    @menu.insertItemWithTitle("Add Point...", action:"addPoint:", keyEquivalent:"", atIndex:0).target = self
    @menu.insertItemWithTitle("Duplicate Point", action:"duplicatePoint:", keyEquivalent:"", atIndex:1).target = self
    @menu.insertItemWithTitle("Delete Point", action:"deletePoint:", keyEquivalent:"", atIndex:2).target = self
    @outlineView.menu = @menu

    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData

    disableProperties    
  end
  
  def book=(book)
    @tabView.add(nil)
    @book = book
    @outlineView.reloadData
    disableProperties
    expandRoot
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
      @tabView.add(nil)
    else
      point = @book.navigation[@outlineView.selectedRow]
      @tabView.add(point)
      textCell.stringValue = point.text
      idCell.stringValue = point.id
      sourceCell.stringValue = point.src
      enableProperties
    end
  end

  def outlineView(outlineView, setObjectValue:object, forTableColumn:tableColumn, byItem:point)
    point.text = object
  end

  def outlineView(outlineView, writeItems:points, toPasteboard:pboard)
    @draggedPoint = points.first
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(@draggedPoint.text, forType:NSStringPboardType)
    true
  end 

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    if parent
      !@draggedPoint.ancestor?(parent) ? NSDragOperationMove : NSDragOperationNone
    elsif @book.navigation.root.size == 1 && @draggedPoint == @book.navigation.root[0]
      NSDragOperationNone
    else
      index = @book.navigation.root.index(@draggedPoint)
      index.nil? || index != childIndex ? NSDragOperationMove : NSDragOperationNone
    end
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    parent = @book.navigation.root unless parent
    return false unless @draggedPoint
    @book.navigation.delete(@draggedPoint)
    parent.insert(childIndex, @draggedPoint)
    @outlineView.reloadData
    selectPoint(@draggedPoint)
    @draggedPoint = nil
    true
  end
  
  def selectPoint(point)
    if point
      row = @outlineView.rowForItem(point)
      indices = NSIndexSet.indexSetWithIndex(row)
      @outlineView.selectRowIndexes(indices, byExtendingSelection:false)      
    else
      @outlineView.deselectAll(nil)
    end
  end
  
  def addPoint(sender)
  end
  
  def duplicatePoint(sender)
    return if @book.navigation[@outlineView.selectedRow] == -1
    current = @book.navigation[@outlineView.selectedRow]
    point = Point.new(current.parent)
    point.text = current.text.dup
    point.item = current.item
    current.parent.insert(current.parent.index(current) + 1, point)
    @outlineView.reloadData
    selectPoint(point)
  end
  
  def deletePoint(sender)
    return if @book.navigation[@outlineView.selectedRow] == -1
    @book.navigation[@outlineView.selectedRow].parent.delete(current)
    @outlineView.reloadData
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
    href, fragment = sourceCell.stringValue.split('#')
    item = @book.manifest.itemWithHref(href)
    unless item
      showErrorAlert("Source is not valid: #{sourceCell.stringValue}")
      sourceCell.stringValue = point.src
      return
    end
    point.item = item
    point.fragment = fragment
    @tabView.add(point)
  end
  
  def expandRoot
    if @book.navigation.root.size > 0
      @outlineView.expandItem(@book.navigation.root[0], expandChildren:false)
    end
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
  
  def showErrorAlert(message)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "Error"
    alert.informativeText = message
    alert.runModal
  end
  
end
