class ManifestController < NSResponder

  attr_accessor :bookController, :outlineView, :propertiesForm, :mediaTypePopUpButton

  def awakeFromNib
    @manifest = @bookController.document.manifest

    # configure popup menu
    @menu = NSMenu.alloc.initWithTitle("")
    @menu.addAction("Add Files...", "showAddFilesSheet:", self)
    @menu.addActionWithSeparator("New Directory", "newDirectory:", self)
    @menu.addActionWithSeparator("Add to Spine", "addSelectedItemsToSpine:", self)
    @menu.addActionWithSeparator("Mark as Cover Image", "markAsCover:", self)
    @menu.addAction("Delete...", "showDeleteSelectedItemsSheet:", self)
    
    # configure media types popup button
    # Media.types.each {|type| @mediaTypePopUpButton.addItemWithTitle(type)}

    displaySelectedItemProperties
  end

  def numberOfChildrenOfItem(item)
    return 0 unless @manifest # guard against SDK bug
    item == self ? @manifest.root.size : item.size
  end

  def isItemExpandable(item)
    item == self ? true : item.directory?
  end

  def child(index, ofItem:item)
    item == self ? @manifest.root[index] : item[index]
  end

  def objectValueForTableColumn(tableColumn, byItem:item)
    item == self ? "MANIFEST" : item.name
  end

  def willDisplayCell(cell, forTableColumn:tableColumn, item:item)
    if item == self
      cell.font = NSFont.boldSystemFontOfSize(11.0)
      cell.image = NSImage.imageNamed('manifest.png')
      cell.menu = nil
    else
      cell.font = NSFont.systemFontOfSize(11.0)
      cell.menu = @menu
      if item.directory?
        cell.image = NSImage.imageNamed('folder.png')
      else
        cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
      end
    end
  end

  def selectionDidChange(notification)
    displaySelectedItemProperties
  end

  def setObjectValue(value, forTableColumn:tableColumn, byItem:item)
    value = value.sanitize
    if item.parent.childWithName(value)
      showChangeNameCollisionAlert(value)
    else
      changeItemName(item, value)
    end
  end

  def writeItems(items, toPasteboard:pboard)
    itemIds = items.map { |item| item.id }
    pboard.declareTypes(["ManifestItemsPboardType"], owner:self)
    pboard.setPropertyList(itemIds.to_plist, forType:"ManifestItemsPboardType")
    true
  end

  def validateDrop(info, proposedItem:parent, proposedChildIndex:childIndex)
    # set the proposed parent to nil if it is manifest controller
    parent = nil if parent == self
    
    # get available data types from pastebaord
    types = info.draggingPasteboard.types
    
    # data is coming from the manifest controller
    if types.containsObject("ManifestItemsPboardType")      
      # get hrefs data from pastebaord
      itemIds = load_plist(info.draggingPasteboard.propertyListForType("ManifestItemsPboardType"))
      
      # loop over each href and validate
      itemIds.each do |id|
        
        # get item with associated href
        item = @manifest.itemWithId(id.to_s)
        
        return NSDragOperationNone unless item
        
        # reject if proposed parent is nil and item is already a child or root
        if (parent == nil && item.parent == @manifest.root)
          return NSDragOperationNone
        end

        # reject if proposed parent isn't nil or a directory
        if (parent != nil && !parent.directory?)
          return NSDragOperationNone
        end
        
        # reject if item is an ancestor of proposed parent
        if parent && parent.ancestor?(item)
          return NSDragOperationNone
        end
      end
      
      # accept drag
      return NSDragOperationMove
    end
    
    # data is coming from the filesystem
    if types.containsObject(NSFilenamesPboardType)
      # reject unless proposed parent is nil or a directory
      if parent == nil || parent.directory?
        @outlineView.setDropRow(-1, dropOperation:NSTableViewDropAbove)
        return NSDragOperationCopy
      else
        return NSDragOperationNone
      end
    end
    
    # no supported data types were found on pastebaord
    return NSDragOperationNone
  end

  def acceptDrop(info, item:parent, childIndex:childIndex)
    parent = @manifest.root if parent == self
    return false unless parent.directory?
    items = []
    if @outlineView == info.draggingSource
      itemIds = load_plist(info.draggingPasteboard.propertyListForType("ManifestItemsPboardType"))
      items = itemIds.map { |id| @manifest.itemWithId(id) }
      newParents = Array.new(items.size, parent)
      newIndexes = Array.new(items.size, childIndex)
      moveItems(items, newParents, newIndexes)
    else
      filepaths = info.draggingPasteboard.propertyListForType(NSFilenamesPboardType)
      addFiles(filepaths, parent, childIndex)
    end
    true
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    cell.font = NSFont.systemFontOfSize(11.0)
    if item.directory?
      cell.image = NSImage.imageNamed('folder.png')
    else
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
    end
  end

  def selectedItem
    selectedItems.first
  end

  def selectedItems
    @outlineView.delegate.selectedItemsForController(self)
  end

  def selectedItemParentAndChildIndex
    item = selectedItem
    item ? [item.parent, item.parent.index(item)] : [@manifest.root, -1]
  end

  def showAddFilesSheet(sender)
    panel = NSOpenPanel.openPanel
    panel.title = "Add Files"
    panel.setPrompt("Select")
    panel.setAllowsMultipleSelection(true)
    panel.beginSheetForDirectory(nil, file:nil, types:nil, modalForWindow:@bookController.window,
    modalDelegate:self, didEndSelector:"addFilesSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def addFilesSheetDidEnd(openPanel, returnCode:code, contextInfo:info)
    if code == NSOKButton
      filepaths = openPanel.URLs.map { |url| url.path }
      addFiles(filepaths)
    end
  end

  def addFiles(filepaths, parent=nil, childIndex=nil)
    parent, childIndex = selectedItemParentAndChildIndex unless parent && childIndex
    items = []
    collisionFilenames = []
    filepaths.each do |path|
      item = @manifest.addFile(path, parent, childIndex)
      if item
        items << item
      else
        collisionFilenames << path.lastPathComponent
      end
    end
    undoManager.prepareWithInvocationTarget(self).deleteItems(items)
    unless undoManager.isUndoing
      undoManager.actionName = "Add #{pluralize(items.size, "Item")} to Manifest"
    end
    reloadDataAndSelectItems(items)
    showAddFilesCollisionAlert(collisionFilenames) unless collisionFilenames.empty?
    items
  end

  def addFile(filepath, parent=nil, childIndex=nil)
    addFiles([filepath], parent, childIndex).first
  end

  def moveItems(items, newParents, newIndexes)
    # check for collisions
    collisionFilenames = []
    items.each_with_index do |item, i|
      collisionFilenames << item.name if newParents[i].childWithName(item.name)
    end

    # warn about collisions and return
    unless collisionFilenames.empty?
      showMoveFilesCollisionAlert(collisionFilenames)
      return
    end

    # no filename collisions so proceed with moving items
    oldParents = []
    oldIndexes = []
    items.each_with_index do |item, i|
      oldParents << item.parent
      oldIndexes << item.parent.index(item)
      @manifest.move(item, newIndexes[i], newParents[i])
    end
    undoManager.prepareWithInvocationTarget(self).moveItems(items.reverse, oldParents.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(items.size, "Item")} in Manifest"
    end
    
    @outlineView.reloadData
    @outlineView.expandItems(newParents)
    @outlineView.selectItems(items)
    
    # reloadDataAndSelectItems(items)
  end

  def delete(sender)
    showDeleteSelectedItemsSheet(sender)
  end

  def showDeleteSelectedItemsSheet(sender)
    alert = NSAlert.alloc.init
    alert.messageText = "Are you sure you want to delete the selected items? Any references will be removed from the Table of Contents and Spine."
    alert.informativeText = "You cannot undo this action."
    alert.addButtonWithTitle("OK")
    alert.addButtonWithTitle("Cancel")
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:self, didEndSelector:"deleteSelectedItemsSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def deleteSelectedItemsSheetDidEnd(alert, returnCode:code, contextInfo:info)
    deleteItems(selectedItems) if code == NSAlertFirstButtonReturn
  end

  def deleteItems(items)
    items.each do |item|
      @bookController.tabViewController.removeObject(item)
      @bookController.spineController.deleteItem(item, false)
      @bookController.navigationController.deletePointsReferencingItem(item)
      @manifest.delete(item)
    end
    reloadDataAndSelectItems(nil)
    markBookEdited
  end

  def addSelectedItemsToSpine(sender)
    @bookController.addItemsToSpine(selectedItems)
  end

  def markAsCover(sender)
    item = selectedItem
    return unless item && !item.directory?
    @bookController.document.metadata.cover = item
    markBookEdited
  end

  def newDirectory(sender)
    parent, index = selectedItemParentAndChildIndex
    name = "New Directory"
    i = 1
    while true
      break unless parent.childWithName(name)
      i += 1
      name = "New Directory #{i}"
    end
    item = Item.new(parent, name, nil, "directory")
    @manifest.insert(index, item, parent)
    reloadDataAndSelectItems([item])
    markBookEdited
    @outlineView.editColumn(0, row:@outlineView.selectedRow, withEvent:NSApp.currentEvent, select:true)
  end

  def showUndeclaredFilesSheet
    ignore = %w{META-INF/container.xml mimetype}
    ignore = ignore.map { |item| "#{@bookController.document.unzipPath}/#{item}" }
    ignore << @bookController.document.container.opfPath
    ignore << @manifest.ncx.path
    @undeclared = []
    Dir.glob("#{@bookController.document.unzipPath}/**/*").each do |entry|
      next if ignore.include?(entry) || File.directory?(entry)
      @undeclared << entry unless @manifest.itemWithHref(entry)
    end
    if @undeclared.empty?
      @bookController.runModalAlert("All files are properly declared in the manifest.")
    else
      relativePaths = @undeclared.map {|entry| @bookController.document.relativePathFor(entry) }
      alert = NSAlert.alloc.init
      alert.messageText = "The following files are present but not declared in the manifest."
      alert.informativeText = "#{relativePaths.join("\n")}\n"
      alert.addButtonWithTitle("Move to Trash")
      alert.addButtonWithTitle("Cancel")
      alert.beginSheetModalForWindow(@bookController.window, modalDelegate:self, didEndSelector:"deleteUndeclaredFilesSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
    end
  end

  def deleteUndeclaredFilesSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertFirstButtonReturn
      urls = @undeclared.map { |filepath| NSURL.fileURLWithPath(filepath) }
      NSWorkspace.sharedWorkspace.performSelector(:"recycleURLs:completionHandler:", withObject:urls, withObject:nil)
      markBookEdited
    end
  end

  def changeSelectedItemProperties(sender)
    item = selectedItem
    changeItemName(item, nameCell.stringValue)
    changeItemId(item, idCell.stringValue)
    changeItemMediaType(item, @mediaTypePopUpButton.title)
  end

  def changeItemName(item, value)
    return if item.name == value
    undoManager.prepareWithInvocationTarget(self).changeItemName(item, item.name)
    undoManager.actionName = "Change Name"
    item.name = value
    reloadDataAndSelectItems([item])
  end

  def changeItemId(item, value)
    return if item.id == value
    undoManager.prepareWithInvocationTarget(self).changeItemId(item, item.id)
    undoManager.actionName = "Change ID"
    item.id = value
    reloadDataAndSelectItems([item])
  end

  def changeItemMediaType(item, value)
    return if item.mediaType == value
    undoManager.prepareWithInvocationTarget(self).changeItemMediaType(item, item.mediaType)
    undoManager.actionName = "Change Media Type"
    item.mediaType = value
    reloadDataAndSelectItems([item])
  end

  def validateUserInterfaceItem(interfaceItem)
    case interfaceItem.action
    when :"showDeleteSelectedItemsSheet:", :"delete:"
      @outlineView.numberOfSelectedRows > 0
    when :"addSelectedItemsToSpine:"
      selectedItems.reject { |item| item.flowable? }.empty?
    when :"markAsCover:"
      @outlineView.numberOfSelectedRows == 1 && selectedItem.imageable?
    else
      true
    end
  end

  private

  def reloadDataAndSelectItems(items)
    @manifest.sort
    @outlineView.reloadData
    @outlineView.selectItems(items)
    displaySelectedItemProperties
    # @bookController.window.makeFirstResponder(@outlineView)
  end

  def displaySelectedItemProperties
    return
    # item = selectedItem
    # if item && !item.directory?
    #   propertyCells.each {|cell| cell.enabled = true}
    #   @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
    #   nameCell.stringValue = item.name
    #   idCell.stringValue = item.id
    #   if item.renderable?
    #     @bookController.tabViewController.addObject(item)        
    #   end
    # else
    #   propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
    #   @mediaTypePopUpButton.selectItemWithTitle('')
    # end
  end

  def nameCell
    @propertiesForm.cellAtIndex(0)
  end

  def idCell
    @propertiesForm.cellAtIndex(1)
  end

  def propertyCells
    @propertyCells ||= [nameCell, idCell, mediaTypePopUpButton]
  end

  def showChangeNameCollisionAlert(name)
    showAlertSheet("The name \"#{name}\" is already taken. Please choose a different name.")
  end

  def showAddFilesCollisionAlert(filenames)
    showAlertSheet("The following files were not added because items with the same names already exist.", filenames.join("\n"))
  end

  def showMoveFilesCollisionAlert(filenames)
    showAlertSheet("The following files were not moved because items with the same names already exist.", filenames.join("\n"))
  end

  def showAlertSheet(messageText, informativeText='')
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:nil, didEndSelector:nil, contextInfo:nil)
  end

  def markBookEdited
    @bookController.document.updateChangeCount(NSSaveOperation)
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end
