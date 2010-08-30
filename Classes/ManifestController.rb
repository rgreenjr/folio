class ManifestController

  attr_accessor :manifest, :outlineView, :inspectorForm, :typePopUpButton
  attr_accessor :webViewController, :textViewController

  def awakeFromNib
    disableInspector
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
    return if @outlineView.selectedRow < 0
    item = @manifest[@outlineView.selectedRow]
    @webViewController.item = item
    @textViewController.item = item
    if item.directory?
      disableInspector
    else
      enableInspector
      nameCell.stringValue = item.name
      idCell.stringValue = item.id
    end
    @typePopUpButton.selectItemWithTitle(item.mediaType)
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
    cell.editable = true
    cell.lineBreakMode = NSLineBreakByTruncatingTail
    cell.selectable = true      
    if item.directory?
      cell.image = NSImage.imageNamed('folder.png')
    else
      image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
      image.scalesWhenResized = true
      image.size = NSSize.new(16, 16)
      cell.image = image
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

  def updateAttribute(attribuute, cell)
    item = @manifest[@outlineView.selectedRow]
    return unless item
    item.send("#{attribuute}=", cell.stringValue)
    cell.stringValue = item.send(attribuute)
    @outlineView.needsDisplay = true
  end

  def nameCell
    @inspectorForm.cellAtIndex(0)
  end

  def idCell
    @inspectorForm.cellAtIndex(1)
  end

  def disableInspector
    nameCell.enabled = false
    nameCell.stringValue = ''
    idCell.enabled = false
    idCell.stringValue = ''
    @typePopUpButton.enabled = false
  end

  def enableInspector
    nameCell.enabled = true
    idCell.enabled = true
    @typePopUpButton.enabled = true
  end

end
