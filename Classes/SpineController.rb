class SpineController < NSResponder

  attr_accessor :outlineView

  def awakeFromNib
    @menu = NSMenu.alloc.initWithTitle("")
    @menu.addActionWithSeparator("Add to Table of Contents", "addSelectedItemRefsToNavigation:", self)
    @menu.addAction("Delete", "deleteSelectedItemRefs:", self)
  end

  def bookController=(controller)
    @bookController = controller
    @spine = @bookController.document.spine
  end

  def toggleSpine(sender)
    @outlineView.isItemExpanded(self) ? @outlineView.collapseItem(self) : @outlineView.expandItem(self)
  end

  def numberOfChildrenOfItem(item)
    return 0 unless @spine # guard against SDK bug
    item == self ? @spine.size : 0
  end

  def isItemExpandable(item)
    item == self
  end

  def child(index, ofItem:item)
    item == self ? @spine[index] : nil
  end

  def objectValueForTableColumn(tableColumn, byItem:item)
    item == self ? "SPINE" : item.item.name
  end

  def willDisplayCell(cell, forTableColumn:tableColumn, item:item)
    if item == self
      cell.font = NSFont.boldSystemFontOfSize(11.0)
      cell.image = NSImage.imageNamed('spine.png')
      cell.menu = nil
    else
      cell.font = NSFont.systemFontOfSize(11.0)
      # cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(""))
      cell.menu = @menu
    end
  end

  # write the ids of the selected itemRefs to the pastebaord
  def writeItems(itemRefs, toPasteboard:pboard)
    itemRefIds = itemRefs.map { |itemRef| itemRef.id }
    pboard.declareTypes([ItemRef::PBOARD_TYPE], owner:self)
    pboard.setPropertyList(itemRefIds.to_plist, forType:ItemRef::PBOARD_TYPE)
    true
  end

  def validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
    # reject if the data soruce isn't our outlineView
    return NSDragOperationNone unless info.draggingSource == @outlineView

    # reject unless the proposed parent is spine controller
    return NSDragOperationNone unless parent == self

    # get available data types from pastebaord
    types = info.draggingPasteboard.types

    if types.containsObject(ItemRef::PBOARD_TYPE)
      # read itemRef ids from pastebaord
      itemRefIds = load_plist(info.draggingPasteboard.propertyListForType(ItemRef::PBOARD_TYPE))

      # process each itemRef id
      itemRefIds.each do |id|
        # get itemRef with corresponding id
        itemRef = @spine.itemRefWithId(id)

        # reject if itemRef not found
        return NSDragOperationNone unless itemRef

        # reject drag if itemRef item isn't flowable
        return NSDragOperationNone unless itemRef.item.flowable?
      end

      # data looks good so allow move operation
      return NSDragOperationMove

    elsif types.containsObject(Item::PBOARD_TYPE)

      # read item ids from pastebaord
      itemIds = load_plist(info.draggingPasteboard.propertyListForType(Item::PBOARD_TYPE))
      
      # process each item id
      itemIds.each do |id|

        # get item with associated id
        item = @bookController.document.manifest.itemWithId(id)
        
        # reject drag unless item is found
        return NSDragOperationNone unless item
        
        # reject drag if item isn't flowable
        return NSDragOperationNone unless item.flowable?

      end

      # data looks good so allow copy operation
      return NSDragOperationCopy
    else
      # no supported data types were found on pastebaord
      return NSDragOperationNone
    end
  end

  def acceptDrop(info, item:parent, childIndex:childIndex)
    # get available data types from pastebaord
    types = info.draggingPasteboard.types

    if types.containsObject(ItemRef::PBOARD_TYPE)
      # drag data from spine controller, so read itemRef ids from pastebaord
      itemRefIds = load_plist(info.draggingPasteboard.propertyListForType(ItemRef::PBOARD_TYPE))
      
      itemRefs = []
      newIndexes = []
      offset = 0
      itemRefIds.reverse.each do |id|
        itemRef = @spine.itemRefWithId(id)
        itemRefs << itemRef
        oldIndex = @spine.index(itemRef)
        if oldIndex < childIndex
          offset += 1
          newIndexes << childIndex - offset
        else
          newIndexes << childIndex
        end
      end

      # move the specified itemRefs
      moveItemRefs(itemRefs, newIndexes)

      # itemRefIds.reverse.each do |id|
      #   itemRef = @spine.itemRefWithId(id)
      #   currentIndex = @spine.index(itemRef)
      #   childIndex -= 1 if currentIndex < childIndex
      #   moveItemRef(itemRef, childIndex)
      # end

      return true
    elsif types.containsObject(Item::PBOARD_TYPE)
      # drag data from manifest controller, read item ids from pastebaord
      itemIds = load_plist(info.draggingPasteboard.propertyListForType(Item::PBOARD_TYPE))

      # create a new ItemRef for each item id
      items = itemIds.map { |id| ItemRef.new(@bookController.document.manifest.itemWithId(id)) }

      # reverse the insertion sequence to maintain order unless childIndex == -1
      items = items.reverse unless childIndex == -1

      # create an array of indexes
      newIndexes = Array.new(items.size, childIndex)

      # add new itemrefs to spine
      addItemRefs(items, newIndexes)

      return true
    else
      # no supported data types were found on pastebaord
      return false
    end
  end

  def tableView(tableView, rowForItem:item)
    @spine.index(item)
  end

  def addItemRefs(itemRefs, indexes=nil)
    indexes ||= Array.new(itemRefs.size, -1)
    itemRefs.each_with_index do |item, i|
      index = indexes[i]
      @spine.insert(index, item)
    end
    undoManager.prepareWithInvocationTarget(self).deleteItemRefs(itemRefs, true)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{"Spine ItemRef".pluralize(itemRefs.size)}"
    end
    reloadDataAndSelectItems(itemRefs)
  end

  def selectedItemRefs
    @outlineView.delegate.selectedItemsForController(self)
  end

  def addSelectedItemRefsToNavigation(sender)
    items = selectedItemRefs.map { |itemRef| itemRef.item }
    @bookController.selectionViewController.navigationController.newPointsWithItems(items)
  end

  def deleteSelectedItemRefs(sender)
    deleteItemRefs(selectedItemRefs)
  end

  def deleteItemRefsWithItem(item)
    deleteItemRefs(@spine.itemRefsWithItem(item), false)
  end

  def deleteItemRefs(itemRefs, allowUndo=true)
    return unless itemRefs && !itemRefs.empty?

    indexes = []
    itemRefs.each do |item|
      index = @spine.index(item)
      @spine.delete_at(index)
      indexes << index
    end

    if allowUndo
      undoManager.prepareWithInvocationTarget(self).addItemRefs(itemRefs.reverse, indexes.reverse)
      unless undoManager.isUndoing
        undoManager.actionName = "Delete #{"Spine ItemRef".pluralize(itemRefs.size)}"
      end
    end

    reloadDataAndSelectItems(nil)
  end

  def moveItemRefs(itemRefs, newIndexes)
    oldIndexes = []
    itemRefs.each_with_index do |itemRef, index|
      oldIndexes << @spine.move(itemRef, newIndexes[index])
    end
    undoManager.prepareWithInvocationTarget(self).moveItemRefs(itemRefs.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(itemRefs.size, "Spine ItemRef")}"
    end
    reloadDataAndSelectItems(itemRefs)
  end

  # def moveItemRef(itemRef, newIndex)
  #   oldIndex = @spine.move(itemRef, newIndex)
  #   puts "moveItemRef #{itemRef} from #{oldIndex} to #{newIndex}"
  #   undoManager.prepareWithInvocationTarget(self).moveItemRef(itemRef, oldIndex)
  #   unless undoManager.isUndoing
  #     undoManager.actionName = "Move Spine ItemRef"
  #   end
  #   reloadDataAndSelectItems([itemRef])
  # end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"addSelectedItemRefsToNavigation:", :"deleteSelectedItemRefs:"
      @outlineView.numberOfSelectedRows > 0
    when :"toggleSpine:"
      interfaceItem.title = @outlineView.isItemExpanded(self) ? "Collapse Spine" : "Expand Spine"
    else
      true
    end
  end

  def window
    @bookController.window
  end

  def undoManager
    @undoManager ||= window.undoManager
  end

  private

  def reloadDataAndSelectItems(itemRefs)
    @outlineView.reloadData
    @outlineView.selectItems(itemRefs)
    window.makeFirstResponder(@outlineView)
  end

end
