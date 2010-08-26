class LayoutController
  
  attr_accessor :layout, :outlineView, :webView, :textView
  
	def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @outlineView.registerForDraggedTypes([NSStringPboardType])
    @outlineView.reloadData
	end
	
	def layout=(layout)
	  @layout = layout
    @outlineView.reloadData
  end
  
  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @outlineView.dataSource && @layout # guard against cocoa bug
    item ? item.size : @layout.root.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && item.size > 0
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item[index] : @layout.root[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.text
  end
  
  def outlineViewItemDidExpand(notification)
    notification.userInfo['NSObject'].expanded = true
  end

  def outlineViewItemDidCollapse(notification)
    notification.userInfo['NSObject'].expanded = false
  end

  def outlineViewSelectionDidChange(notification)
    return if @outlineView.selectedRow < 0
    point = @layout[@outlineView.selectedRow]
    webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(point.url)))
  end

  def outlineView(outlineView, setObjectValue:object, forTableColumn:tableColumn, byItem:item)
    item.text = object
  end
  
  def outlineView(outlineView, writeItems:items, toPasteboard:pboard)
    puts "writeRowsWithIndexes"
    @draggedItems = items
    pboard.declareTypes([NSStringPboardType], owner:self)
		pboard.setString(items.first.text, forType:NSStringPboardType)
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
