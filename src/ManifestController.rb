class ManifestController

  attr_accessor :outlineView, :propertiesForm, :mediaTypePopUpButton, :tabView

  def awakeFromNib
    @menu = NSMenu.alloc.initWithTitle("Manifest Contextual Menu")
    @menu.insertItemWithTitle("Add...", action:"showAddItemPanel:", keyEquivalent:"", atIndex:0).target = self
    @menu.insertItemWithTitle("Delete", action:"deleteItem:", keyEquivalent:"", atIndex:1).target = self
    @menu.insertItemWithTitle("New Folder", action:"addDirectory:", keyEquivalent:"", atIndex:2).target = self
    @outlineView.menu = @menu

    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:nil)
    
    Media.types.each {|type| @mediaTypePopUpButton.addItemWithTitle(type)}
    
    disableProperties
  end

  def book=(book)
    @book = book
    @outlineView.reloadData
  end

  def tabViewSelectionDidChange(notification)
    selectItem(notification.object.selectedItem)
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
    if @outlineView.selectedRow < 0
      disableProperties
      item = nil
      @tabView.add(nil)
      @mediaTypePopUpButton.selectItemWithTitle('')
    else
      item = @book.manifest[@outlineView.selectedRow]
      if item.directory?
        disableProperties
        @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
        @tabView.add(nil)
      else
        enableProperties
        nameCell.stringValue = item.name
        idCell.stringValue = item.id
        @mediaTypePopUpButton.selectItemWithTitle(item.mediaType)
        @tabView.add(item)
      end
    end
  end

  def outlineView(outlineView, setObjectValue:object, forTableColumn:tableColumn, byItem:item)
    item.name = object
  end

  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    @draggedItem = items.first
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(@draggedItem.href, forType:NSStringPboardType)
    true
  end 

  def outlineView(outlineView, validateDrop:info, proposedItem:parent, proposedChildIndex:childIndex)
    if parent
      parent.directory? && parent != @draggedItem.parent && parent != @draggedItem && !@draggedItem.ancestor?(parent) ? NSDragOperationMove : NSDragOperationNone
    else
      @draggedItem.parent != @book.manifest.root ? NSDragOperationMove : NSDragOperationNone
    end
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    parent = @book.manifest.root unless parent
    return false unless @draggedItem && parent.directory?
    @book.manifest.move(@draggedItem, childIndex, parent)
    @outlineView.reloadData
    selectItem(@draggedItem)
    @draggedItem = nil
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
    if @outlineView.selectedRow == -1
      [@book.manifest.root, -1]
    else
      item = @book.manifest[@outlineView.selectedRow]
      [item.parent, item.parent.index(item)]
    end
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
    selectItem(item)
  end
  
  def deleteItem(sender)
    
  end

  def addDirectory(sender)
    parent, index = currentSelectionParentAndIndex    
    item = Item.new(parent, "New Directory", nil, "directory")
    parent.insert(index, item)
    @outlineView.reloadData
    selectItem(item)
  end

  def selectItem(item)
    if item
      row = @outlineView.rowForItem(item)
      indices = NSIndexSet.indexSetWithIndex(row)
      @outlineView.selectRowIndexes(indices, byExtendingSelection:false)
    else
      @outlineView.deselectAll(nil)
    end
  end
  
  def changeName(sender)
    updateAttribute('name', nameCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeMediaType(sender)
    @book.manifest[@outlineView.selectedRow].mediaType = @mediaTypePopUpButton.title
  end

  private

  def updateAttribute(attribute, cell)
    item = @book.manifest[@outlineView.selectedRow]
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

  def disableProperties
    propertyCells.each {|cell| cell.enabled = false; cell.stringValue = ''}
  end

  def enableProperties
    propertyCells.each {|cell| cell.enabled = true}
  end

  def propertyCells
    [nameCell, idCell, mediaTypePopUpButton]
  end

end
