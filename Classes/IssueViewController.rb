class IssueViewController < NSViewController

  attr_accessor :bookController
  attr_accessor :outlineView
  attr_accessor :noIssuesImageView

  def initWithBookController(controller)
    initWithNibName("IssueView", bundle:nil)
    @bookController = controller
    @items = []
    self
  end
  
  def awakeFromNib
    imageCell = ImageCell.new
    imageCell.editable = false
    imageCell.selectable = false
    @outlineView.tableColumns.first.dataCell = imageCell
    
    @outlineView.delegate = self
    @outlineView.dataSource = self

    # set single click target and action
    @outlineView.target = self
    @outlineView.action = "displayCurrentSelection:"

    # receive notification when item issues are updated 
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"itemIssuesDidChange:", name:"ItemIssuesDidChange", object:nil)

    # show default image
    showNoIssuesImage
  end
  
  def visible?
    view && !view.hidden? && !view.superview.nil?
  end

  def refresh
    Alert.runModal(@bookController.window, "@bookController.document is nil") if @bookController.document == nil
    
    Alert.runModal(@bookController.window, "@bookController.document.manifest is nil") if @bookController.document.manifest == nil
    
    # get all items with validation issues
    @items = @bookController.document.manifest.itemsWithIssues
    
    # add book if it has any valitions issues
    @items.unshift(@bookController.document) if @bookController.document.hasIssues?
    
    # show default image if there are no issues
    @items.empty? ? showNoIssuesImage : showIssuesView
    
    # refresh outlineView
    @outlineView.deselectAll(self)
    @outlineView.reloadData
    
    # expand every item in the outlineView
    @outlineView.expandItem(nil, expandChildren:true)
  end
  
  def itemIssuesDidChange(notification)
    refresh
  end
  
  def showNoIssuesImage
    @outlineView.hidden = true
    @noIssuesImageView.hidden = false
  end
  
  def showIssuesView
    @outlineView.hidden = false
    @noIssuesImageView.hidden = true
  end

  def outlineView(outlineView, numberOfChildrenOfItem:object)
    return 0 unless @outlineView.dataSource
    object ? object.issues.size : @items.size
  end

  def outlineView(outlineView, isItemExpandable:object)
    object.class != Issue
  end

  def outlineView(outlineView, child:index, ofItem:object)
    object ? object.issues[index] : @items[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:object)
    if object.class == Item
      object.name
    elsif object.class == Book
      object.metadata.title # "Book"
    else
      object.displayString
    end
  end
  
  def outlineViewSelectionDidChange(notification)
    displayCurrentSelection(self)
  end
  
  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:object)
    cell.font = NSFont.systemFontOfSize(11.0)
    if object.class == Item
      # cell.badgeCount = object.issues.size
      cell.badgeCount = nil
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(object.name))
    elsif object.class == Book
      # cell.badgeCount = object.issues.size
      cell.badgeCount = nil
      cell.image = NSImage.imageNamed('book.png')
    else
      cell.badgeCount = nil
      cell.image = nil
      # cell.image = NSImage.imageNamed('wrench.png')
    end
  end

  def displayCurrentSelection(sender)
    object = @outlineView.itemAtRow(@outlineView.selectedRow)
    return unless object
    if object.class == Item
      @bookController.tabbedViewController.addObject(object)
    elsif object.class == Issue
      parent = @outlineView.parentForItem(object)
      if parent && parent.class == Item
        @bookController.tabbedViewController.addObject(parent)
        @bookController.tabbedViewController.showSourceView
        if object.lineNumber
          @bookController.tabbedViewController.sourceViewController.selectLineNumber(object.lineNumber + 1)
        end
      end
    end
  end

end
