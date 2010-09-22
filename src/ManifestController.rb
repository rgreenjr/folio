class ManifestController

  attr_accessor :manifest, :outlineView, :propertiesForm, :typePopUpButton
  attr_accessor :webViewController, :textViewController

  def awakeFromNib
    disableProperties
    @outlineView.tableColumns.first.dataCell = ImageCell.new
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
  end

  def manifest=(manifest)
    @manifest = manifest
    @outlineView.reloadData
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource && @manifest # guard against SDK bug
    item ? item.size : @manifest.root.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item[index] : @manifest.root[index]
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
      item = @manifest[@outlineView.selectedRow]
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
    puts "writeRowsWithIndexes"
    @draggedItems = items
    pboard.declareTypes([NSStringPboardType], owner:self)
    pboard.setString(items.first.name, forType:NSStringPboardType)
    true
  end 

  def outlineView(outlineView, validateDrop:info, proposedItem:item, proposedChildIndex:childIndex)
    puts "validateDrop"
    NSDragOperationMove
  end

  def outlineView(outlineView, acceptDrop:info, item:item, childIndex:childIndex)
    return false unless @draggedItems
    puts "acceptDrop"
    @raggedItems = nil
    @outlineView.reloadData
    true
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    if item.directory?
      cell.image = NSImage.imageNamed('folder.png')
    else
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
    end
  end

  def changeName(sender)
    updateAttribute('name', nameCell)
  end

  def changeID(sender)
    updateAttribute('id', idCell)
  end

  def changeMediaType(sender)
    @manifest[@outlineView.selectedRow].mediaType = @typePopUpButton.title
  end

  private

  def updateAttribute(attribute, cell)
    item = @manifest[@outlineView.selectedRow]
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
