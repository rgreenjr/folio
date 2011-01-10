class ManifestController < NSViewController

  attr_accessor :outlineView, :propertiesForm, :mediaTypePopUpButton, :tabView, :headerView

  def init
    initWithNibName("Manifest", bundle:nil)
  end

  def awakeFromNib
    # configure popup menu
    menu = NSMenu.alloc.initWithTitle("")
    menu.addAction("Add File...", "showAddFilesSheet:", self)
    menu.addActionWithSeparator("New Directory...", "newDirectory:", self)
    menu.addActionWithSeparator("Add to Spine", "addToSpine:", self)
    menu.addActionWithSeparator("Mark as Cover", "markAsCover:", self)
    menu.addAction("Delete...", "showDeleteItemsSheet:", self)
    @outlineView.menu = menu

    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType, NSFilenamesPboardType])
    @outlineView.reloadData
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:@tabView)

    # configure media types popup button
    Media.types.each {|type| @mediaTypePopUpButton.addItemWithTitle(type)}

    @headerView.title = "Manifest"

    displayItemProperties
  end

  def book=(book)
    @book = book
    @outlineView.reloadData
  end
  
  def tabViewSelectionDidChange(notification)
    @outlineView.selectItem(notification.object.selectedItem)
  end

  def selectedItem
    @outlineView.selectedRow == -1 ? nil : @book.manifest[@outlineView.selectedRow]
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
    displayItemProperties
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:item)
    value = value.sanitize
    item.parent.find(value) ? showNameErrorAlert(value) : item.name = value
    postChangeNotification
  end

  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setPropertyList(items.map {|item| item.href}.to_plist, forType:NSStringPboardType)
    true
  end

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    if info.draggingSource == @outlineView
      plist = load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType))
      plist.each do |path|
        item = @book.manifest.itemWithHref(path)
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
      load_plist(info.draggingPasteboard.propertyListForType(NSStringPboardType)).each do |path|
        item = @book.manifest.itemWithHref(path)
        items << item
        @book.manifest.move(item, childIndex, parent)
      end
    else
      info.draggingPasteboard.propertyListForType(NSFilenamesPboardType).each do |path|
        # TODO check for name collisions
        item = Item.new(parent, File.basename(path))
        item.content = File.read(path)
        items << item
        parent.insert(childIndex, item)
      end
    end
    @book.manifest.sort
    @outlineView.reloadData
    @outlineView.selectItems(items)
    postChangeNotification
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

  def currentSelectionParentAndIndex
    item = selectedItem
    item ? [item.parent, item.parent.index(item)] : [@book.manifest.root, -1]
  end

  def showAddFilesSheet(sender)
    panel = NSOpenPanel.openPanel
    panel.title = "Add Files"
    panel.setPrompt("Select")
    panel.setAllowsMultipleSelection(true)
    panel.beginSheetForDirectory(nil, file:nil, types:nil, modalForWindow:@outlineView.window, modalDelegate:self, didEndSelector:"addFilesSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def addFilesSheetDidEnd(panel, returnCode:code, contextInfo:info)
    return unless code == NSOKButton
    filepaths = panel.URLs.map { |url| url.path }
    addFiles(filepaths)
  end
  
  def addFiles(filepaths)
    parent, index = currentSelectionParentAndIndex
    items = filepaths.map { |path| @book.manifest.insertFileAtPath(path, parent, index) }      
    @book.manifest.sort
    @outlineView.reloadData
    @outlineView.selectItems(items)
    postChangeNotification
    items
  end

  def addFile(filepath)
    addFiles([filepath]).first
  end

  def showDeleteItemsSheet(sender)
    return if @outlineView.numberOfSelectedRows == 0
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete the selected files?", defaultButton:"OK", alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:"")
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:self, didEndSelector:"showDeleteItemsSheetDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end

  def showDeleteItemsSheetDidEnd(panel, returnCode:code, contextInfo:info)
    return unless code == NSOKButton
    items = []
    @outlineView.selectedRowIndexes.reverse_each do |index|
      items << @book.manifest[index]
    end
    deleteItems(items)
  end
  
  def deleteItems(items)
    items.each do |item|
      @tabView.remove(item)
      @book.manifest.delete(item)
    end
    @book.manifest.sort
    @outlineView.reloadData
    postChangeNotification
  end

  def addToSpine(sender)
    @outlineView.selectedRowIndexes.each do |index|
      item = @book.manifest[index]
      @book.spine.insert(-1, item)
    end
    postChangeNotification
  end

  def markAsCover(sender)
    item = selectedItem
    return unless item && !item.directory?
    @book.metadata.cover = item
    postChangeNotification
  end

  def newDirectory(sender)
    parent, index = currentSelectionParentAndIndex
    name = "New Directory"
    i = 1
    while true
      break unless parent.find(name)
      i += 1
      name = "New Directory #{i}"
    end
    item = Item.new(parent, name, nil, "directory")
    parent.insert(index, item)
    @book.manifest.sort
    @outlineView.reloadData
    @outlineView.selectItem(item)
    @outlineView.editColumn(0, row:@outlineView.selectedRow, withEvent:NSApp.currentEvent, select:true)
    postChangeNotification
  end

  def showUnregisteredFiles
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
      Alert.runModal("All files are registered in the book's manifest.")
    else
      relativePaths = @unregistered.map {|entry| @book.relativePathFor(entry) }
      alert = NSAlert.alertWithMessageText("The following files are present but not registered in the book's manifest.", defaultButton:"Move to Trash", 
        alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:"#{relativePaths.join("\n")}\n")

      alert.beginSheetModalForWindow(NSApp.mainWindow, modalDelegate:self,
        didEndSelector:"deleteUnregisteredFilesSheetDidEnd:returnCode:contextInfo:",
        contextInfo:nil)
    end
  end
  
  def deleteUnregisteredFilesSheetDidEnd(alert, returnCode:code, contextInfo:info)
    if code == NSAlertDefaultReturn
      urls = @unregistered.map { |filepath| NSURL.fileURLWithPath(filepath) }
      NSWorkspace.sharedWorkspace.performSelector(:"recycleURLs:completionHandler:", withObject:urls, withObject:nil)
      postChangeNotification
    end
  end

  def changeName(sender)
    puts "changeName"
    updateAttribute('name', nameCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeMediaType(sender)
    selectedItem.mediaType = @mediaTypePopUpButton.title
    postChangeNotification
  end

  private

  def updateAttribute(attribute, cell)
    item = selectedItem
    return unless item
    item.send("#{attribute}=", cell.stringValue)
    cell.stringValue = item.send(attribute)
    @outlineView.needsDisplay = true
    postChangeNotification
  end

  def nameCell
    @propertiesForm.cellAtIndex(0)
  end

  def idCell
    @propertiesForm.cellAtIndex(1)
  end

  def displayItemProperties
    item = selectedItem
    if @outlineView.numberOfSelectedRows == 1 && !item.directory?
      propertyCells.each {|cell| cell.enabled = true}
      @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
      nameCell.stringValue = item.name
      idCell.stringValue = item.id
      @tabView.add(item)
    else
      propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
      @mediaTypePopUpButton.selectItemWithTitle('')
    end
  end

  def propertyCells
    [nameCell, idCell, mediaTypePopUpButton]
  end

  def showNameErrorAlert(name)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle "OK"
    alert.messageText = "The name \"#{name}\" is already taken. Please choose a different name."
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:nil, didEndSelector:nil, contextInfo:nil)
  end

  def validateUserInterfaceItem(menuItem)
    case menuItem.action
    when :"showDeleteItemsSheet:"
      return false if @outlineView.numberOfSelectedRows < 1
    when :"addToSpine:"
      return false if @outlineView.selectedRowIndexes.empty?
      @outlineView.selectedRowIndexes.each do |index|
        return false unless @book.manifest[index].flowable?
      end
    when :"markAsCover:"
      return false if @outlineView.numberOfSelectedRows != 1 || !selectedItem.imageable?
    end
    true
  end

  def postChangeNotification
    NSNotificationCenter.defaultCenter.postNotificationName("ManifestDidChange", object:self)
  end

  def undoManager
    @undoManager ||= @outlineView.window.undoManager
  end

end
