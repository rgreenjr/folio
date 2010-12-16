class NavigationController

  attr_accessor :navigation, :outlineView, :propertiesForm, :tabView

  def awakeFromNib
    @menu = NSMenu.alloc.initWithTitle("Navigation Contextual Menu")
    @menu.insertItemWithTitle("Add Point...", action:"addPoint:", keyEquivalent:"", atIndex:0).target = self
    @menu.insertItemWithTitle("Duplicate", action:"duplicatePoint:", keyEquivalent:"", atIndex:1).target = self
    @menu.addItem(NSMenuItem.separatorItem)
    @menu.insertItemWithTitle("Delete", action:"deletePoint:", keyEquivalent:"", atIndex:3).target = self
    @outlineView.menu = @menu

    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData

    displayPointProperties
  end

  def book=(book)
    @tabView.add(nil)
    @book = book
    @outlineView.reloadData
    displayPointProperties
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
    displayPointProperties
  end

  def outlineView(outlineView, setObjectValue:object, forTableColumn:tableColumn, byItem:point)
    changePointText(point, object)
  end

  def outlineView(outlineView, writeItems:points, toPasteboard:pboard)
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(points.map {|item| item.id}.to_plist, forType:NSStringPboardType)
    true
  end

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    return NSDragOperationNone unless info.draggingSource == @outlineView
    operation = NSDragOperationNone
    load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType)).each do |id|
      point = @book.navigation.pointWithId(id)
      if parent
        operation = !point.ancestor?(parent) ? NSDragOperationMove : NSDragOperationNone
      elsif @book.navigation.root.size == 1 && point == @book.navigation.root[0]
        operation = NSDragOperationNone
      else
        index = @book.navigation.root.index(point)
        operation = index.nil? || index != childIndex ? NSDragOperationMove : NSDragOperationNone
      end
    end
    operation
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    parent = @book.navigation.root unless parent
    points = []
    parents = []
    plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    plist.each do |id|
      point = @book.navigation.pointWithId(id)
      @book.navigation.delete(point)
      parent.insert(childIndex, point)
      points << point
      parents << parent
    end
    @outlineView.reloadData
    parents.each do |parent|
      @outlineView.expandItem(parent)
    end
    @outlineView.selectItems(points)
    postChangeNotification
    true
  end

  def addPoint(sender)
  end

  def appendItem(item)
    point = @book.navigation.insertItem(item)
    @outlineView.reloadData
    @outlineView.selectItem(point)
    postChangeNotification
  end

  def duplicatePoint(sender)
    new_point = @book.navigation.duplicate(selectedPoint)
    @outlineView.reloadData
    @outlineView.selectItem(new_point)
    postChangeNotification
  end

  def deletePoint(sender)  	
    @outlineView.selectedRowIndexes.reverse_each do |index|
      point = @book.navigation[index]
      @book.navigation.delete(point)
    end
    @outlineView.reloadData
    @outlineView.deselectAll(nil)
    postChangeNotification
  end

  def undoManager
    @outlineView.window.undoManager
  end

  def changeText(sender)
    return if selectedPoint.text == textCell.stringValue
    changePointText(selectedPoint, textCell.stringValue)
  end

  def changePointText(point, text)
    undoManager.prepareWithInvocationTarget(self).changePointText(point, point.text)
    undoManager.actionName = "Title Change"
    point.text = text
    displayPointProperties
    @outlineView.needsDisplay = true
    postChangeNotification
  end

  def changeID(sender)
    return if selectedPoint.id == idCell.stringValue
    changePointID(selectedPoint, idCell.stringValue)
  end

  def changePointID(point, id)
    undoManager.prepareWithInvocationTarget(self).changePointID(point, point.id)
    undoManager.actionName = "ID Change"
    point.id = id
    displayPointProperties
    @outlineView.needsDisplay = true
    postChangeNotification
  end

  def changeSource(sender)
    point = selectedPoint
    return unless point
    href, fragment = sourceCell.stringValue.split('#')
    fragment = "" unless fragment
    item = @book.manifest.itemWithHref(href)
    if item
      if point.item != item || point.fragment != fragment
        changePointSource(point, item, fragment)
      end
    else
      showErrorAlert("Source is not valid: #{sourceCell.stringValue}")
      sourceCell.stringValue = point.src
    end
  end

  def changePointSource(point, item, fragment)
    undoManager.prepareWithInvocationTarget(self).changePointSource(point, point.item, point.fragment)
    undoManager.actionName = "Source Change"
    point.item = item
    point.fragment = fragment
    @tabView.add(point)
    displayPointProperties
    @outlineView.needsDisplay = true
    postChangeNotification
  end
  
  def expandRoot
    if @book.navigation.root.size > 0
      @outlineView.expandItem(@book.navigation.root[0], expandChildren:false)
    end
  end

  private

  def displayPointProperties
    point = selectedPoint
    if @outlineView.numberOfSelectedRows == 1
      propertyCells.each {|cell| cell.enabled = true}
      textCell.stringValue = point.text
      idCell.stringValue = point.id
      sourceCell.stringValue = point.src
      @tabView.add(point)
    else
      propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
    end
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

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"deletePoint:"
      return false if @outlineView.numberOfSelectedRows < 1
    when :"duplicatePoint:"
      return false if @outlineView.numberOfSelectedRows != 1
    when :"addPoint:"
      return false
    end
    true
  end

  def postChangeNotification
    NSNotificationCenter.defaultCenter.postNotificationName("NavigationDidChange", object:self)
  end

end
