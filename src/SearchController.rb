class SearchController
  
  attr_accessor :book, :searchField, :replaceField
  attr_accessor :outlineView, :webViewController, :textViewController
  
  def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
  end

  def book=(book)
    @book = book
    @search = nil
    @searchField.stringValue = ''
    @outlineView.reloadData
  end
  
  def show(sender)
    
  end
  
  def hide(sender)
    puts "hide"
  end

  def search(sender)
    @search = Search.new(searchField.stringValue, book)
    @outlineView.reloadData
    # @search.each {|match| @outlineView.expandItem(match, expandChildren:false) }
  end
  
  def previousMatch(sender)
    return unless @search && @search.size > 0
    row = @outlineView.selectedRow
    return if row - 1 < 0    
    indices = NSIndexSet.indexSetWithIndex(row - 1)
    @outlineView.selectRowIndexes(indices, byExtendingSelection:false)    
  end
  
  def nextMatch(sender)
    return unless @search && @search.size > 0
    row = @outlineView.selectedRow
    row = 0 if row < 0
    return if row + 1 >= @search.total
    indices = NSIndexSet.indexSetWithIndex(row + 1)
    @outlineView.selectRowIndexes(indices, byExtendingSelection:false)    
  end
  
  def replace(sender)
    puts "replace"
    return unless @search && @search.size > 0
    replacement = replaceField.stringValue
    return if replacement.empty?
    row = @outlineView.selectedRow
    return unless row > 0
    match = @search.walk(row)
    return unless match.leaf?
    @textViewController.replace(match.range, replacement)
    puts "done"
    match.changed = true
    puts "changed"
    match.parent.each do |m|
      puts "sliding #{m.message} by #{replacement.size - match.range.length}"
      m.slide(replacement.size - match.range.length)
    end
  end
  
  def replaceAll(sender)
    puts "replaceAll"
    # replacement = replaceField.stringValue
    # return if replacement.empty?
    # @search.each do |match| 
    #   @textViewController.replace(match.range, replacement) unless match.leaf?
    # end
  end
  
  def enableSearch
    @search && !@search.empty? && !replaceField.stringValue.empty?
  end

  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @search
    item ? item.size : @search.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && !item.empty?
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item[index] : @search[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.message
  end

  def outlineViewItemDidExpand(notification)
    notification.userInfo['NSObject'].expanded = true
  end

  def outlineViewItemDidCollapse(notification)
    notification.userInfo['NSObject'].expanded = false
  end

  def outlineViewSelectionDidChange(notification)
    return if @outlineView.selectedRow < 0
    match = @search.walk(@outlineView.selectedRow)
    @textViewController.item = match.item
    @webViewController.item = match.item
    if match.empty?
      @textViewController.textView.scrollRangeToVisible(match.range)
      @textViewController.textView.showFindIndicatorForRange(match.range)
    end
  end
  
  def outlineView(outlineView, dataCellForTableColumn:tableColumn, item:match)
    match.leaf? ? NSTextFieldCell.alloc.init : ImageCell.new
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:match)
    cell.editable = false
    cell.selectable = false
    cell.font = NSFont.systemFontOfSize(11.0)
    unless match.leaf?
      cell.badgeCount = match.size
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(match.item.name))
    end
  end
    
end