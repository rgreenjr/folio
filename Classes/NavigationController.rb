class NavigationController < NSResponder

  attr_accessor :bookController, :outlineView

  def awakeFromNib
    @navigation = @bookController.document.navigation

    @menu = NSMenu.alloc.initWithTitle("")
    @menu.addAction("New Point...", "newPoint:", self)
    @menu.addActionWithSeparator("Duplicate", "duplicateSelectedPoint:", self)
    @menu.addAction("Delete", "deleteSelectedPoints:", self)
  end
  
  def numberOfChildrenOfItem(point)
    return 0 unless @navigation # guard against SDK bug
    point == self ? @navigation.root.size : point.size
  end

  def isItemExpandable(point)
    point == self ? true : point.size > 0
  end

  def child(index, ofItem:point)
    point == self ? @navigation.root[index] : point[index]
  end

  def objectValueForTableColumn(tableColumn, byItem:point)
    point == self ? "TABLE OF CONTENTS" : point.text
  end

  def willDisplayCell(cell, forTableColumn:tableColumn, item:item)
    if item == self
      # cell.textColor = NSColor.colorWithDeviceRed(0.39, green:0.44, blue:0.5, alpha:1.0)
      cell.font = NSFont.boldSystemFontOfSize(11.0)
      cell.image = NSImage.imageNamed('toc.png')
      cell.menu = nil
    else
      # cell.textColor = NSColor.darkGrayColor
      cell.font = NSFont.systemFontOfSize(11.0)
      cell.image = nil
      cell.menu = @menu
    end
  end

  def setObjectValue(value, forTableColumn:tableColumn, byItem:point)
    # changePointText(point, value)
  end

  def writeItems(points, toPasteboard:pboard)
    pointIds = points.map { |point| point.id }
    pboard.declareTypes(["NavigationPointsPboardType"], owner:self)
    pboard.setPropertyList(pointIds.to_plist, forType:"NavigationPointsPboardType")
    true
  end

  def validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
    # set the proposed parent to root if it is navigation controller
    parent = @navigation.root if parent == self
    
    # reject if the data soruce isn't our outlineView
    return NSDragOperationNone if info.draggingSource != @outlineView

    # get available data types from pastebaord
    types = info.draggingPasteboard.types     
    
    # data contains item ids
    if types.containsObject("SpineItemRefsPboardType")
      itemIds = load_plist(info.draggingPasteboard.propertyListForType("SpineItemRefsPboardType"))
      items = itemIds.each do |id|
        item = @bookController.document.manifest.itemWithId(id)
        # reject if the item isn't flowable
        return NSDragOperationNone unless item && item.flowable?
      end
      return NSDragOperationCopy    
    end
        
    # return move operation if data is from navigation controller and proposed parent isn't a descendant 
    if types.containsObject("NavigationPointsPboardType")
      pointIds = load_plist(info.draggingPasteboard.propertyListForType("NavigationPointsPboardType"))
      pointIds.each do |id|
        point = @navigation.pointWithId(id)
        return NSDragOperationNone if point.ancestor?(parent)
      end
      return NSDragOperationMove
    end
    
    # no supported data types were found on pastebaord
    return NSDragOperationNone
  end

  def acceptDrop(info, item:parent, childIndex:childIndex)
    # set the proposed parent to root if it is navigation controller
    parent = @navigation.root if parent == self

    # get available data types from pastebaord
    types = info.draggingPasteboard.types

    # create new points if data comes from spine controller
    if types.containsObject("SpineItemRefsPboardType")
      itemIds = load_plist(info.draggingPasteboard.propertyListForType("SpineItemRefsPboardType"))
      items = itemIds.map { |id| @bookController.document.manifest.itemWithId(id) }
      
      # reverse the insertion sequence to maintain order unless childIndex == -1
      items = items.reverse unless childIndex == -1
      
      newIndexes = Array.new(items.size, childIndex)
      newParents = Array.new(items.size, parent)
      newPointsWithItems(items, newIndexes, newParents)
      return true
    end
    
    # move existing points if data comes from navigation controller
    if types.containsObject("NavigationPointsPboardType")
      plist = load_plist(info.draggingPasteboard.propertyListForType("NavigationPointsPboardType"))
      points = plist.map { |id| @navigation.pointWithId(id) }

      # reverse the insertion sequence to maintain order unless childIndex == -1
      points = points.reverse unless childIndex == -1

      newIndexes = Array.new(points.size, childIndex)
      newParents = Array.new(points.size, parent)
      movePoints(points, newIndexes, newParents)
      return true
    end
    
    # should never reach here; return false if we do
    false
  end

  def selectedPoint
    selectedPoints.first
  end

  def selectedPoints
    @outlineView.delegate.selectedItemsForController(self)
  end

  def movePoints(points, newIndexes, newParents)
    oldParents = []
    oldIndexes = []
    points.each_with_index do |point, i|
      index, parent = @navigation.indexAndParent(point)
      oldIndexes << index
      oldParents << parent
      @navigation.move(point, newIndexes[i], newParents[i])
    end

    undoManager.prepareWithInvocationTarget(self).movePoints(points.reverse, oldIndexes.reverse, oldParents.reverse)
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

  def newPointsWithItems(items, newIndexes=nil, newParents=nil)
    points = items.map { |item| Point.new(item, item.name) }
    newParents ||= Array.new(points.size, @navigation.root)
    newIndexes ||= Array.new(points.size, -1)
    addPoints(points, newIndexes, newParents)
  end

  def addPoints(points, newIndexes, newParents)
    points.each_with_index do |point, i|
      puts "adding #{point.text}, index = #{newIndexes[i]}, parent = #{newParents[i].text}"
      @navigation.insert(point, newIndexes[i], newParents[i])
    end

    undoManager.prepareWithInvocationTarget(self).deletePoints(points, true, 0)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{pluralize(points.size, "Point")} to Navigation"
    end

    @outlineView.reloadData
    @outlineView.expandItems(newParents)
    @outlineView.selectItems(points)
  end

  def duplicateSelectedPoint(sender)
    duplicatePoint(selectedPoint)
  end

  def duplicatePoint(point)
    clone = @navigation.duplicate(point)
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
  def deletePoints(points, allowUndo=true, level=0)
    # recursively delete children first
    points.each do |point|
      deletePoints(point.children.reverse, allowUndo, level + 1)
    end

    indexes = []
    parents = []
    points.each do |point|
      index, parent = @navigation.indexAndParent(point)
      indexes << index
      if parent
        parents << parent
        indent = "   " * level
        puts "#{indent}deleting #{point.text}, parent = #{parent.text}, index = #{index}"
        @navigation.delete(point)
      else
        raise "unable to delete parentless point #{point.text}, index = #{index}"
      end
    end
    
    puts "---"

     if allowUndo
      undoManager.prepareWithInvocationTarget(self).addPoints(points.reverse, indexes.reverse, parents.reverse)
      unless undoManager.isUndoing
        undoManager.actionName = "Delete #{pluralize(points.size, "Point")} from Navigation"
      end
    end

    reloadDataAndSelectPoints(nil)
  end

  def deletePointsReferencingItem(item)
    points = @navigation.select { |point| point.item == item }
    deletePoints(points, false)
  end

  private

  def reloadDataAndSelectPoints(points)
    @outlineView.reloadData
    @outlineView.selectItems(points)
    # @bookController.window.makeFirstResponder(@outlineView)
  end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
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
    @undoManager ||= @bookController.window.undoManager
  end

end
