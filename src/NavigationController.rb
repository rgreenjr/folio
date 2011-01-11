class NavigationController < NSViewController

  attr_accessor :outlineView, :propertiesForm, :tabView, :headerView

  def init
    initWithNibName("Navigation", bundle:nil)
  end

  def awakeFromNib
    menu = NSMenu.alloc.initWithTitle("")
    menu.addAction("New Point...", "newPoint:", self)
    menu.addActionWithSeparator("Duplicate", "duplicatePoint:", self)
    menu.addAction("Delete", "deletePoint:", self)
    @outlineView.menu = menu

    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData

    @headerView.title = "Navigation"

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

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:index)
    parent = @book.navigation.root unless parent
    plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    points = plist.map { |id| [@book.navigation.pointWithId(id), index, parent] }
    movePoints(points)
    true
  end

  def movePoints(points)
    undoPoints = points.map do |point, newIndex, newParent|
      index, parent = @book.navigation.index_and_parent(point)
      [point, index, parent]
    end

    undoManager.prepareWithInvocationTarget(self).movePoints(undoPoints)
    points.each do |point, newIndex, newParent|
      @book.navigation.move(point, newIndex, newParent)
    end
    undoManager.actionName = "Move"

    @outlineView.reloadData

    points.each do |point, newIndex, newParent|
      @outlineView.expandItem(newParent)
    end

    @outlineView.selectItems(points.map{|point, newIndex, newParent| point})

    postChangeNotification
  end

  def newPoint(sender)
    # return unless selectedPoint
    # parent, index = currentSelectionParentAndIndex
    # addPoints([[Point.new(selectedPoint.item, "New Point", "id"), index + 1, parent]])
  end

  def addPoints(array)
    undoPoints = []
    parents = []
    array.reverse_each do |point, index, parent|
      @book.navigation.insert(point, index, parent)
      undoPoints << point
      parents << parent
    end

    undoManager.prepareWithInvocationTarget(self).deletePoints(undoPoints)
    undoManager.actionName = "Add"

    @outlineView.reloadData
    @outlineView.expandItems(parents)
    @outlineView.selectItems(undoPoints)
    postChangeNotification
  end

  def duplicatePoint(sender)
    duplicatePointNow(selectedPoint)
  end

  def duplicatePointNow(point)
    clone = @book.navigation.duplicate(point)
    undoManager.prepareWithInvocationTarget(self).deletePoints([clone])
    undoManager.actionName = "Duplicate"
    @outlineView.reloadData
    @outlineView.selectItem(clone)
    postChangeNotification
  end

  def deletePoint(sender)
    points = []
    @outlineView.selectedRowIndexes.reverse_each do |index|
      points << @book.navigation[index]
    end
    deletePoints(points)
  end

  # TODO need to handle points with children !!!!
  def deletePoints(array)

    # recursively delete all children first
    array.each do |point|
      point.each do |child|
        deletePoints([child])
      end
    end

    # create undo data
    undoPoints = array.map do |point|
      index, parent = @book.navigation.index_and_parent(point)
      [point, index, parent]
    end
    undoManager.prepareWithInvocationTarget(self).addPoints(undoPoints)
    undoManager.actionName = "Delete"

    # perfrom actual deletion
    array.each do |point|
      @book.navigation.delete(point)
    end

    @outlineView.reloadData
    @outlineView.deselectAll(nil)
    postChangeNotification
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
    # TODO need to check for collisions and dehash/hash
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
      Alert.runModal("Unable to Locate Source", "Please make sure the file is included in the manifest.\n\n#{sourceCell.stringValue}")
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
    if @book && @book.navigation.root.size > 0
      @outlineView.expandItem(@book.navigation.root[0], expandChildren:false)
    end
  end

  private

  def displayPointProperties
    if @outlineView.numberOfSelectedRows == 1
      propertyCells.each {|cell| cell.enabled = true}
      point = selectedPoint
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
    @propertyCells ||= [textCell, idCell, sourceCell]
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"deletePoint:"
      return false if @outlineView.numberOfSelectedRows < 1
    when :"duplicatePoint:"
      return false if @outlineView.numberOfSelectedRows != 1
    when :"addPoint:"
      return false if @outlineView.numberOfSelectedRows != 1
    end
    true
  end

  def postChangeNotification
    NSDocumentController.sharedDocumentController.currentDocument.updateChangeCount(NSSaveOperation)
    NSNotificationCenter.defaultCenter.postNotificationName("NavigationDidChange", object:self)
  end

  def undoManager
    @undoManager ||= @outlineView.window.undoManager
  end

end
