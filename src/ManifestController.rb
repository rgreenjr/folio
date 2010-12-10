class ManifestController

  attr_accessor :outlineView, :propertiesForm, :mediaTypePopUpButton, :tabView

  def awakeFromNib
    # configure popup menu
    @menu = NSMenu.alloc.initWithTitle("Manifest Contextual Menu")
    @menu.insertItemWithTitle("Add File...", action:"showAddItemPanel:", keyEquivalent:"", atIndex:0).target = self
    @menu.insertItemWithTitle("Add Directory...", action:"addDirectory:", keyEquivalent:"", atIndex:1).target = self
    @menu.addItem(NSMenuItem.separatorItem)
    @menu.insertItemWithTitle("Mark as Cover", action:"markAsCover:", keyEquivalent:"", atIndex:3).target = self
    @menu.addItem(NSMenuItem.separatorItem)
    @menu.insertItemWithTitle("Delete", action:"showDeleteItemPanel:", keyEquivalent:"", atIndex:5).target = self
    @outlineView.menu = @menu

    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType, NSFilenamesPboardType])
    @outlineView.reloadData
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:nil)
    
    # configure media types popup button
    Media.types.each {|type| @mediaTypePopUpButton.addItemWithTitle(type)}
    
    displayItemProperties(nil)
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
    displayItemProperties(selectedItem)
  end

  def outlineView(outlineView, setObjectValue:value, forTableColumn:tableColumn, byItem:item)
    value = value.sanitize
    item.parent.find(value) ? showNameErrorAlert(value) : item.name = value
  end

  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    @draggedItem = items.first
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(@draggedItem.href, forType:NSStringPboardType)
    true
  end 

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    if info.draggingSource == @outlineView
      if parent
        @draggedItem.ancestor?(parent) ? NSDragOperationNone : NSDragOperationMove
      else
        @draggedItem.parent == @book.manifest.root ? NSDragOperationNone : NSDragOperationMove
      end
    else
      if info.draggingPasteboard.types.containsObject(NSFilenamesPboardType)
        if parent && !parent.directory?
          NSDragOperationNone
        else
          @outlineView.setDropRow(-1, dropOperation:NSTableViewDropAbove)
          NSDragOperationCopy
        end
      else
        NSDragOperationNone
      end
    end
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    if @outlineView == info.draggingSource
      parent = @book.manifest.root unless parent
      return false unless @draggedItem && parent.directory?
      @book.manifest.move(@draggedItem, childIndex, parent)
      @outlineView.reloadData
      @outlineView.selectItem(@draggedItem)
      @draggedItem = nil
    else
      parent = @book.manifest.root unless parent
      return false unless parent.directory?
      info.draggingPasteboard.propertyListForType(NSFilenamesPboardType).each do |path|
        # TODO check for name collisions
        item = Item.new(parent, File.basename(path))
        item.content = File.read(path)
        parent.insert(childIndex, item)        
      end
      @outlineView.reloadData
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
  
  def currentSelectionParentAndIndex
    item = selectedItem
    item ? [item.parent, item.parent.index(item)] : [@book.manifest.root, -1]
  end

  def showAddItemPanel(sender)
    panel = NSOpenPanel.openPanel
    panel.title = "Add Item"
    panel.setPrompt("Select")
    panel.setAllowsMultipleSelection(false)
    panel.beginSheetForDirectory(nil, file:nil, types:nil, modalForWindow:@outlineView.window, modalDelegate:self, didEndSelector:"addItemPanelDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end
  
  def addItemPanelDidEnd(panel, returnCode:code, contextInfo:info)
    return unless code == NSOKButton
    path = panel.URLs[0].path
    parent, index = currentSelectionParentAndIndex
    item = Item.new(parent, File.basename(path))
    item.content = File.read(path)  
    parent.insert(index, item)
    @outlineView.reloadData
    @outlineView.selectItem(item)
  end
  
  def showDeleteItemPanel(sender)
    item = selectedItem
    return unless item
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete the item \"#{item.name}\"?", defaultButton:"OK", alternateButton:"Cancel", otherButton:nil, informativeTextWithFormat:"")    
    alert.beginSheetModalForWindow(@outlineView.window, modalDelegate:self, didEndSelector:"showDeleteItemPanelDidEnd:returnCode:contextInfo:", contextInfo:nil)    
  end
  
  def showDeleteItemPanelDidEnd(panel, returnCode:code, contextInfo:info)
    return unless code == NSOKButton
    parent, index = currentSelectionParentAndIndex
    parent.delete_at(index)
    @outlineView.reloadData
  end
  
  def markAsCover(sender)
    item = selectedItem
    return unless item && !item.directory?
    @book.metadata.cover = item
  end

  def addDirectory(sender)
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
    @outlineView.reloadData
    @outlineView.selectItem(item)
    @outlineView.editColumn(0, row:@outlineView.selectedRow, withEvent:NSApp.currentEvent, select:true)
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
  end

  private

  def updateAttribute(attribute, cell)
    item = selectedItem
    return unless item
    item.send("#{attribute}=", cell.stringValue)
    cell.stringValue = item.send(attribute)
    @outlineView.needsDisplay = true
  end

  def nameCell
    @propertiesForm.cellAtIndex(0)
  end

  def idCell
    @propertiesForm.cellAtIndex(1)
  end

  def displayItemProperties(item)
    if item
      unless item.directory?
        propertyCells.each {|cell| cell.enabled = true}
        @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
        nameCell.stringValue = item.name
        idCell.stringValue = item.id
        @tabView.add(item)
      end
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

end
