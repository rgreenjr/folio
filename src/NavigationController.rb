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

    displayPointProperties(nil)
  end
  
  def book=(book)
    @tabView.add(nil)
    @book = book
    @outlineView.reloadData
    displayPointProperties(nil)
    expandRoot
  end
  
  def selectedPoint
    @outlineView.selectedRow == -1 ? nil : @book.navigation[@outlineView.selectedRow]
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
    displayPointProperties(selectedPoint)
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
    return false unless @draggedPoint
    parent = @book.navigation.root unless parent
    @book.navigation.delete(@draggedPoint)
    parent.insert(childIndex, @draggedPoint)
    @outlineView.reloadData
    @outlineView.selectItem(@draggedPoint)
    @draggedPoint = nil
    true
  end
  
  def addPoint(sender)
  end
  
  def duplicatePoint(sender)
    current = selectedPoint
    return unless current
    point = Point.new(current.parent)
    point.text = current.text.dup
    point.item = current.item
    current.parent.insert(current.parent.index(current) + 1, point)
    @outlineView.reloadData
    @outlineView.selectItem(point)
  end
  
  def deletePoint(sender)
    point = selectedPoint
    return unless point
    point.parent.delete(point)
    @outlineView.reloadData
  end

  def changeText(sender)
    updateAttribute('text', textCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeSource(sender)
    point = selectedPoint
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

  def displayPointProperties(point)
    if point
      propertyCells.each {|cell| cell.enabled = true}
      textCell.stringValue = point.name
      idCell.stringValue = point.id
      sourceCell.stringValue = point.src
    else
      propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
    end
    @tabView.add(point)
  end

  def updateAttribute(attribute, cell)
    point = selectedPoint
    return unless point
    point.send("#{attribute}=", cell.stringValue)
    cell.stringValue = point.send(attribute)
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
