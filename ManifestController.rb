class ManifestController

  attr_accessor :manifest, :outlineView, :webViewController, :textViewController

	def awakeFromNib
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

end
