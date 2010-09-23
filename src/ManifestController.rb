class ManifestController

  attr_accessor :outlineView, :propertiesForm, :typePopUpButton
  attr_accessor :webViewController, :textViewController

  def awakeFromNib
    disableProperties
    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
  end

  def book=(book)
    @book = book
    @outlineView.reloadData
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource && @book # guard against SDK bug
    item ? item.size : @book.manifest.root.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.size > 0
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
      @webViewController.item = nil
      @textViewController.item = nil
      @typePopUpButton.selectItemWithTitle('')
    else
      item = @book.manifest[@outlineView.selectedRow]
      if item.directory?
        disableProperties
        @typePopUpButton.selectItemWithTitle(item.mediaType)
        @webViewController.item = nil
        @textViewController.item = nil
      else
        enableProperties
        nameCell.stringValue = item.name
        idCell.stringValue = item.id
        @typePopUpButton.selectItemWithTitle(item.mediaType)
        @webViewController.item = item
        @textViewController.item = item
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
      parent.directory? && parent != @draggedItem.parent && parent != @draggedItem ? NSDragOperationMove : NSDragOperationNone
    else
      @draggedItem.parent != @book.manifest.root ? NSDragOperationMove : NSDragOperationNone
    end
  end

  def outlineView(outlineView, acceptDrop:info, item:parent, childIndex:childIndex)
    parent = @book.manifest.root if parent.nil?
    return false unless @draggedItem && parent.directory?
    # if @draggedItem.parent == parent
    #   @book.manifest.delete(@draggedItem)
    #   childIndex = -1 if childIndex > parent.size
    #   parent.insert(childIndex, @draggedItem)
    # else
      @book.manifest.move(@draggedItem, childIndex, parent)
    # end
    @outlineView.reloadData
    selectItem(@draggedItem)
    @draggedItem = nil
    true
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    if item.directory?
      cell.image = NSImage.imageNamed('folder.png')
    else
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
    end
  end

  def selectItem(item)
    row = @outlineView.rowForItem(item)
    indices = NSIndexSet.indexSetWithIndex(row)
    @outlineView.selectRowIndexes(indices, byExtendingSelection:false)    
  end
  
  def changeName(sender)
    updateAttribute('name', nameCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeMediaType(sender)
    @book.manifest[@outlineView.selectedRow].mediaType = @typePopUpButton.title
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
    [nameCell, idCell, typePopUpButton]
  end

end
