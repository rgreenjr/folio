class NavigationController < NSResponder

  attr_accessor :outlineView
  attr_accessor :menu
  
  def bookController=(controller)
    @bookController = controller
    @navigation = @bookController.document.navigation

    # register for manifest item deletion notifications
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"manifestWillDeleteItem:", 
        name:"ManifestWillDeleteItem", object:@bookController.document.manifest)
  end
  
  def toggleNavigation(sender)
    @outlineView.isItemExpanded(self) ? @outlineView.collapseItem(self) : @outlineView.expandItem(self)
  end

  def numberOfChildrenOfItem(point)
    return 0 unless @navigation # guard against SDK bug
    point == self ? @navigation.root.size : point.size
  end

  def outlineView(outlineView, viewForTableColumn:tableColumn, item:point)
    if point == self
      view = outlineView.makeViewWithIdentifier("NavigationCell", owner:self)
    else
      if point.hasFragment?
        view = outlineView.makeViewWithIdentifier("PointFragmentCell", owner:self)
      else
        view = outlineView.makeViewWithIdentifier("PointCell", owner:self)
      end
      view.textField.stringValue = point.text
      view.textField.action = "updatePoint:"
      view.textField.target = self
    end
    view
  end
  
  def updatePoint(sender)
    row = @outlineView.rowForView(sender)
    point = @outlineView.itemAtRow(row)
    @bookController.inspectorViewController.pointViewController.changeText(point, sender.stringValue)
  end

  def isItemExpandable(point)
    point == self ? true : point.size > 0
  end

  def child(index, ofItem:point)
    point == self ? @navigation.root[index] : point[index]
  end

  def writeItems(points, toPasteboard:pboard)
    pointIds = points.map { |point| point.id }
    pboard.declareTypes([Point::PBOARD_TYPE], owner:self)
    pboard.setPropertyList(pointIds.to_plist, forType:Point::PBOARD_TYPE)
    true
  end

  def validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
    # set the proposed parent to root if it is the navigation controller
    parent = @navigation.root if parent == self

    # reject if the data soruce isn't our outlineView
    return NSDragOperationNone if info.draggingSource != @outlineView

    # get available data types from pastebaord
    types = info.draggingPasteboard.types

    if types.containsObject(Point::PBOARD_TYPE)

      # read the point ids from the pastebaord 
      pointIds = load_plist(info.draggingPasteboard.propertyListForType(Point::PBOARD_TYPE))

      pointIds.each do |id|

        # get the point with associated id
        point = @navigation.pointWithId(id)

        # reject if the proposed parent is a descendant of point
        return NSDragOperationNone if point.ancestor?(parent)
      end

      # points and proposed parent look good, so return move operation
      return NSDragOperationMove

    elsif types.containsObject(ItemRef::PBOARD_TYPE)

      # read itemRef ids from the pastebaord
      itemRefIds = load_plist(info.draggingPasteboard.propertyListForType(ItemRef::PBOARD_TYPE))

      itemRefIds.each do |id|
        
        # get itemRef with associated id
        itemRef = @bookController.document.spine.itemRefWithId(id)
        
        # reject drag unless itemRef is found
        return NSDragOperationNone unless itemRef
        
        # reject drag if itemRef item isn't parseable
        return NSDragOperationNone unless itemRef.item.parseable?
      end

      # itemRefs look good so return copy operation
      return NSDragOperationCopy    
    else
      # no supported data types were found on pastebaord
      return NSDragOperationNone
    end
  end

  def acceptDrop(info, item:parent, childIndex:childIndex)
    # set the proposed parent to root if it is the navigation controller
    parent = @navigation.root if parent == self

    # get available data types from pastebaord
    types = info.draggingPasteboard.types

    if types.containsObject(Point::PBOARD_TYPE)
      
      # read the point ids from the pastebaord
      plist = load_plist(info.draggingPasteboard.propertyListForType(Point::PBOARD_TYPE))
      
      # get the associated points from navigation
      points = plist.map { |id| @navigation.pointWithId(id) }

      # reverse the insertion sequence to maintain order unless childIndex == -1
      points = points.reverse unless childIndex == -1

      # create the newIndexes and newParents arrays
      newIndexes = Array.new(points.size, childIndex)
      newParents = Array.new(points.size, parent)

      # move points to new locations
      movePoints(points, newIndexes, newParents)

      # return true to indicate success
      return true

    elsif types.containsObject(ItemRef::PBOARD_TYPE)

      # read the itemRef ids from the pastebaord
      itemRefIds = load_plist(info.draggingPasteboard.propertyListForType(ItemRef::PBOARD_TYPE))
      
      # get the associated item for each itemRefs
      items = itemRefIds.map { |id| @bookController.document.spine.itemRefWithId(id).item }
  
      # reverse the insertion sequence to maintain order unless childIndex == -1
      items = items.reverse unless childIndex == -1

      newIndexes = Array.new(items.size, childIndex)
      newParents = Array.new(items.size, parent)

      # add new points
      newPointsWithItems(items, newIndexes, newParents)

      # return true to indicate success
      return true

    else
      # no supported data types were found on pastebaord
      false
    end    
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
      undoManager.actionName = "Move Navigation Point"
    end

    reloadDataAndSelectPoints(points)

    points.each_with_index do |point, i|
      @outlineView.expandItem(newParents[i])
    end

    @outlineView.selectItems(points)
  end

  def showPointCreationPanel(sender)
    @pointPanelController ||= PointPanelController.alloc.initWithBookController(@bookController)
    @pointPanelController.showPointCreationSheet(self)
  end
  
  def addPoint(point)
    index, parent = @navigation.indexAndParent(selectedPoint)
    index = index ? index + 1 : -1
    addPoints([point], [index], [parent || @navigation.root])
  end

  def addPoints(points, newIndexes, newParents)
    points.each_with_index do |point, i|
      @navigation.insert(point, newIndexes[i], newParents[i])
    end

    undoManager.prepareWithInvocationTarget(self).deletePoints(points, true, 0)
    unless undoManager.isUndoing
      undoManager.actionName = "Add to Navigation"
    end

    @outlineView.reloadData
    @outlineView.expandItem(self)
    @outlineView.expandItems(newParents)
    @outlineView.selectItems(points)
  end

  def newPointsWithItems(items, newIndexes=nil, newParents=nil)
    points = items.map { |item| Point.new(item, item.name) }
    newParents ||= Array.new(points.size, @navigation.root)
    newIndexes ||= Array.new(points.size, -1)
    addPoints(points, newIndexes, newParents)
  end
  
  def duplicateSelectedPoint(sender)
    duplicatePoint(selectedPoint)
  end

  def duplicatePoint(point)
    clone = @navigation.duplicate(point)
    undoManager.prepareWithInvocationTarget(self).deletePoints([clone], true, 0)
    undoManager.actionName = "Duplicate Navigation Point"
    reloadDataAndSelectPoints([clone])
  end

  def deleteSelectedPoints(sender)
    deletePoints(selectedPoints, true, 0)
  end

  def deletePoints(points, allowUndo, level)
    return unless points.size > 0
    
    points = removeDescendants(points)
    
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
        @navigation.delete(point)
      else
        raise "unable to delete parentless point #{point.text}, index = #{index}"
      end
    end

     if allowUndo
      undoManager.prepareWithInvocationTarget(self).addPoints(points.reverse, indexes.reverse, parents.reverse)
      unless undoManager.isUndoing
        undoManager.actionName = "Delete Navigation Point"
      end
    end

    reloadDataAndSelectPoints(nil)
  end

  def manifestWillDeleteItem(notification)
    item = notification.userInfo
    if item
      points = @navigation.select { |point| point.item == item }
      deletePoints(points, false, 0)
    end
  end

  private

  def reloadDataAndSelectPoints(points)
    @outlineView.reloadData
    @outlineView.selectItems(points)
  end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"deleteSelectedPoints:", :"delete:"
      selectedPoints.size > 0
    when :"duplicateSelectedPoint:", :"addPoint:"
      selectedPoints.size == 1
    when :"toggleNavigation:"
      interfaceItem.title = @outlineView.isItemExpanded(self) ? "Collapse Navigation" : "Expand Navigation"
    else
      true
    end
  end
  
  def removeDescendants(points)
    descendants = []
    points.each do |point|
      points.each do |inner|
        descendants << inner if point != inner && point.ancestor?(inner)
      end
    end    
    points.reject { |point| descendants.include?(point) }
  end

  def markBookEdited
    @bookController.document.updateChangeCount(NSSaveOperation)
  end

  def window
    @bookController.window
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end
  
end
