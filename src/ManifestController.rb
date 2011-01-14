class ManifestController < NSViewController

  attr_accessor :bookController, :outlineView, :propertiesForm, :mediaTypePopUpButton, :headerView

  def init
    initWithNibName("Manifest", bundle:nil)
  end

  def awakeFromNib
    # configure popup menu
    menu = NSMenu.alloc.initWithTitle("")
    menu.addAction("Add Files...", "showAddFilesSheet:", self)
    menu.addActionWithSeparator("New Directory", "newDirectory:", self)
    menu.addActionWithSeparator("Add to Spine", "addSelectedItemsToSpine:", self)
    menu.addActionWithSeparator("Mark as Cover Image", "markAsCover:", self)
    menu.addAction("Delete...", "showDeleteSelectedItemsSheet:", self)
    @outlineView.menu = menu

    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType, NSFilenamesPboardType])
    @outlineView.reloadData

    # configure media types popup button
    Media.types.each {|type| @mediaTypePopUpButton.addItemWithTitle(type)}

    @headerView.title = "Manifest"

    displaySelectedItemProperties
  end

  def book=(book)
    @book = book
    @outlineView.reloadData
  end

  def selectedItem
    @outlineView.selectedRow == -1 ? nil : @book.manifest[@outlineView.selectedRow]
  end

  def selectedItems
    @outlineView.selectedRowIndexes.map { |index| @book.manifest[index] }
  end

  def selectedItemParentAndChildIndex
    item = selectedItem
    item ? [item.parent, item.parent.index(item)] : [@book.manifest.root, -1]
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource && @book # guard against SDK bug
    item ? item.size : @book.manifest.root.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.directory?
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item[index] : @book.manifest.root[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.name
  end

  def outlineViewItemDidExpand(notification)
    notification.userInfo['NSObject'].expanded = true
  end

  def outlineViewItemDidCollapse(notification)
    notification.userInfo['NSObject'].expanded = false
  end

  def outlineViewSelectionDidChange(notification)
    displaySelectedItemProperties
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:item)
    value = value.sanitize
    if item.parent.childWithName(value)
      showChangeNameCollisionAlert(value)
    else
      changeItemName(item, value)
    end
  end

  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    hrefs = items.map { |item| item.href }
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(hrefs.to_plist, forType:NSStringPboardType)
    true
  end

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    if info.draggingSource == @outlineView
      hrefs = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
      hrefs.each do |href|
        item = @book.manifest.itemWithHref(href)
        if (!parent && item.parent == @book.manifest.root) || (parent && (!parent.directory? || parent.ancestor?(item)))
          return NSDragOperationNone
        end
      end
      NSDragOperationMove
    else
      if info.draggingPasteboard.types.containsObject(NSFilenamesPboardType) && (!parent || parent.directory?)
        @outlineView.setDropRow(-1, dropOperation:NSTableViewDropAbove)
        NSDragOperationCopy
      else
        NSDragOperationNone
      end
    end
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    parent = @book.manifest.root unless parent
    return false unless parent.directory?
    items = []
    if @outlineView == info.draggingSource
      hrefs = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
      items = hrefs.map { |href| @book.manifest.itemWithHref(href) }
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

  def showAddFilesSheet(sender)
    panel = NSOpenPanel.openPanel
    panel.title = "Add Files"
    panel.setPrompt("Select")
    panel.setAllowsMultipleSelection(true)
    panel.beginSheetForDirectory(nil, file:nil, types:nil, modalForWindow:@outlineView.window,
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
      item = @book.manifest.addFile(path, parent, childIndex)
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
      @book.manifest.move(item, newIndexes[i], newParents[i])
    end
    undoManager.prepareWithInvocationTarget(self).moveItems(items.reverse, oldParents.reverse, oldIndexes.reverse)
    unless undoManager.isUndoing
      undoManager.actionName = "Move #{pluralize(items.size, "Item")} in Manifest"
    end
    reloadDataAndSelectItems(items)
  end

  def delete(sender)
    showDeleteSelectedItemsSheet(sender)
  end

  def showDeleteSelectedItemsSheet(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete the selected items? Any references will be removed from the Navigation and Spine.",
        defaultButton:"OK", alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:"You can't undo this action.")
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:self,
        didEndSelector:"deleteSelectedItemsSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def deleteSelectedItemsSheetDidEnd(panel, returnCode:code, contextInfo:info)
    deleteItems(selectedItems) if code == NSOKButton
  end

  def deleteItems(items)
    items.each do |item|
      @bookController.tabViewController.removeObject(item)
      @bookController.spineController.deleteItem(item, false)
      @bookController.navigationController.deletePointsReferencingItem(item)
      @book.manifest.delete(item)
    end
    reloadDataAndSelectItems(nil)
    markBookEdited
  end

  def addSelectedItemsToSpine(sender)
    @book.controller.addItemsToSpine(selectedItems)
  end

  def markAsCover(sender)
    item = selectedItem
    return unless item && !item.directory?
    @book.metadata.cover = item
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
    @book.manifest.insert(index, item, parent)
    reloadDataAndSelectItems([item])
    markBookEdited
    @outlineView.editColumn(0, row:@outlineView.selectedRow, withEvent:NSApp.currentEvent, select:true)
  end

  def showUnregisteredFilesSheet
    ignore = %w{META-INF/container.xml mimetype}
    ignore = ignore.map { |item| "#{@book.unzippath}/#{item}" }
    ignore << @book.container.opfPath
    ignore << @book.manifest.ncx.path
    @unregistered = []
    Dir.glob("#{@book.unzippath}/**/*").each do |entry|
      next if ignore.include?(entry) || File.directory?(entry)
      @unregistered << entry unless @book.manifest.itemWithHref(entry)
    end
    if @unregistered.empty?
      @bookController.runModalAlert("All files are registered in the book's manifest.")
    else
      relativePaths = @unregistered.map {|entry| @book.relativePathFor(entry) }
      alert = NSAlert.alertWithMessageText("The following files are present but not registered in the book's manifest.",
          defaultButton:"Move to Trash", alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:"#{relativePaths.join("\n")}\n")

      alert.beginSheetModalForWindow(@bookController.window, modalDelegate:self,
          didEndSelector:"deleteUnregisteredFilesSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
    end
  end

  def deleteUnregisteredFilesSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertDefaultReturn
      urls = @unregistered.map { |filepath| NSURL.fileURLWithPath(filepath) }
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

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
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
    @book.manifest.sort
    @outlineView.reloadData
    @outlineView.selectItems(items)
    displaySelectedItemProperties
    @bookController.window.makeFirstResponder(@outlineView)
  end

  def displaySelectedItemProperties
    item = selectedItem
    if @outlineView.numberOfSelectedRows == 1 && !item.directory?
      propertyCells.each {|cell| cell.enabled = true}
      @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
      nameCell.stringValue = item.name
      idCell.stringValue = item.id
      @bookController.tabViewController.addObject(item)
    else
      propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
      @mediaTypePopUpButton.selectItemWithTitle('')
    end
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
