class NavigationController < NSViewController

  attr_accessor :bookController, :outlineView, :propertiesForm, :headerView

  def init
    initWithNibName("Navigation", bundle:nil)
  end

  def awakeFromNib
    menu = NSMenu.alloc.initWithTitle("")
    menu.addAction("New Point...", "newPoint:", self)
    menu.addActionWithSeparator("Duplicate", "duplicateSelectedPoint:", self)
    menu.addAction("Delete", "deleteSelectedPoints:", self)
    @outlineView.menu = menu

    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData

    @headerView.title = "Navigation"

    displaySelectedPointProperties
  end

  def book=(book)
    # @bookController.tabViewController.addObject(nil)
    @book = book
    @outlineView.reloadData
    displaySelectedPointProperties
    exapndRootPoint
  end

  def exapndRootPoint
    @outlineView.expandItem(@book.navigation.root[0]) if @book && @book.navigation.root.size > 0
  end

  def selectedPoint
    @outlineView.selectedRow == -1 ? nil : @book.navigation[@outlineView.selectedRow]
  end

  def selectedPoints
    @outlineView.selectedRowIndexes.map { |index| @book.navigation[index] }
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
    displaySelectedPointProperties
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:point)
    changePointText(point, value)
  end

  def outlineView(outlineView, writeItems:points, toPasteboard:pboard)
    pointIds = points.map { |item| item.id }
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(pointIds.to_plist, forType:NSStringPboardType)
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
    plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
    points = plist.map { |id| @book.navigation.pointWithId(id) }
    newParents = Array.new(points.size, parent)
    newIndexes = Array.new(points.size, childIndex)
    movePoints(points, newParents, newIndexes)
    true
  end

  def movePoints(points, newParents, newIndexes)
    oldParents = []
    oldIndexes = []
    points.each_with_index do |point, i|
      index, parent = @book.navigation.index_and_parent(point)
      oldIndexes << index
      oldParents << parent
      @book.navigation.move(point, newIndexes[i], newParents[i])
    end

    undoManager.prepareWithInvocationTarget(self).movePoints(points.reverse, oldParents.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(points.size, "Points")} in Navigation"
    end

    reloadDataAndSelectPoints(points)

    points.each_with_index do |point, i|
      @outlineView.expandItem(newParents[i])
    end

    @outlineView.selectItems(points)
  end

  def newPoint(sender)
    # return unless selectedPoint
    # parent, index = currentSelectionParentAndIndex
    # addPoints([[Point.new(selectedPoint.item, "New Point", "id"), index + 1, parent]])
  end

  def newPointsFromItems(items)
    points = items.map do |item|
      point = Point.new(item, item.name)
      [point, -1, @book.navigation.root]
    end
    addPoints(points)
  end

  def addPoints(points, newParents, newIndexes)
    points.each_with_index do |point, i|
      puts "adding #{point.text}"
      @book.navigation.insert(point, newIndexes[i], newParents[i])
    end

    puts "---"

    undoManager.prepareWithInvocationTarget(self).deletePoints(points)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{pluralize(points.size, "Point")} to Navigation"
    end

    reloadDataAndSelectPoints(points)
  end

  def duplicateSelectedPoint(sender)
    duplicatePoint(selectedPoint)
  end

  def duplicatePoint(point)
    clone = @book.navigation.duplicate(point)
    undoManager.prepareWithInvocationTarget(self).deletePoints([clone])
    undoManager.actionName = "Duplicate Point"
    reloadDataAndSelectPoints([clone])
  end

  def delete(sender)
    deleteSelectedPoints(sender)
  end

  def deleteSelectedPoints(sender)
    deletePoints(selectedPoints)
  end

  # TODO need to handle points with children
  def deletePoints(points, allowUndo=true)
    # recursively delete children first
    # points.each do |point|
    #   deletePoints(point.children)
    # end

    parents = []
    indexes = []
    undoPoints = []
    points.reverse_each do |point|
      index, parent = @book.navigation.index_and_parent(point)
      indexes << index
      parents << parent
      undoPoints << point
      puts "deleting #{point.text}"
      @book.navigation.delete(point)
    end

    puts "---"

    if allowUndo
      undoManager.prepareWithInvocationTarget(self).addPoints(undoPoints, parents, indexes)
      unless undoManager.isUndoing
        undoManager.actionName = "Delete #{pluralize(points.size, "Point")} from Navigation"
      end
    end

    reloadDataAndSelectPoints(points)
  end

  def deletePointsReferencingItem(item)
    points = @book.navigation.select { |point| point.item == item }
    deletePoints(points, false)
  end

  def changeSelectedPointProperties(sender)
    if point = selectedPoint
      changePointText(point, textCell.stringValue)
      changePointID(point, idCell.stringValue)
      changePointSource(point, sourceCell.stringValue)
    end
  end

  def changePointText(point, text)
    return unless point.text != text
    undoManager.prepareWithInvocationTarget(self).changePointText(point, point.text)
    undoManager.actionName = "Change Point Title"
    point.text = text
    reloadDataAndSelectPoints([point])
  end

  # TODO need to check for collisions and dehash/hash
  def changePointID(point, id)
    return unless point.id != id
    if oldID = @book.navigation.changePointId(point, id)
      undoManager.prepareWithInvocationTarget(self).changePointID(point, point.id)
      undoManager.actionName = "Change Point ID"
    else
      @bookController.runModalAlert("A point with ID \"#{id}\" already exists. Please choose a different ID.")
    end
    reloadDataAndSelectPoints([point])
  end

  def changePointSource(point, src)
    return unless point.src != src
    href, fragment = src.split('#')
    item = @book.manifest.itemWithHref(href)
    if item
      undoManager.prepareWithInvocationTarget(self).changePointSource(point, point.src)
      undoManager.actionName = "Change Point Source"
      point.item = item
      point.fragment = fragment
    else
      @bookController.runModalAlert("The manifest doesn't contain an item at \"#{src}\".")
      sourceCell.stringValue = point.src
    end
    reloadDataAndSelectPoints([point])
  end

  private

  def reloadDataAndSelectPoints(points)
    @outlineView.reloadData
    @outlineView.selectItems(points)
    displaySelectedPointProperties
    @bookController.window.makeFirstResponder(@outlineView)
  end

  def displaySelectedPointProperties
    if @outlineView.numberOfSelectedRows == 1
      point = selectedPoint
      propertyCells.each { |cell| cell.enabled = true }
      textCell.stringValue = point.text
      idCell.stringValue = point.id
      sourceCell.stringValue = point.src
      @bookController.tabViewController.addObject(point)
    else
      propertyCells.each { |cell| cell.enabled = false; cell.stringValue = '' }
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
    when :"deleteSelectedPoints:", :"delete:"
      @outlineView.numberOfSelectedRows > 0
    when :"duplicateSelectedPoint:", :"addPoint:"
      @outlineView.numberOfSelectedRows == 1
    else
      true
    end
  end

  def markBookEdited
    @bookController.document.updateChangeCount(NSSaveOperation)
  end

  def undoManager
    @undoManager ||= @outlineView.window.undoManager
  end

end
