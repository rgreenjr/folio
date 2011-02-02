class IssueViewController < NSViewController

  attr_accessor :bookController, :outlineView, :headerView, :noIssuesImageView

  def initWithBookController(bookController)
    initWithNibName("IssueView", bundle:nil)
    @bookController = bookController
    @items = []
    self
  end
  
  def awakeFromNib
    @headerView.title = "Issues"

    imageCell = ImageCell.new
    imageCell.editable = false
    imageCell.selectable = false
    @outlineView.tableColumns.first.dataCell = imageCell

    @outlineView.delegate = self
    @outlineView.dataSource = self

    showNoIssuesImage

    NSNotificationCenter.defaultCenter.addObserver(self, selector:"itemIssuesDidChange:", name:"ItemIssuesDidChange", object:nil)
  end
  
  def refresh
    @items = @bookController.document.manifest.select { |item| item.hasIssues? }
    @items.unshift(@bookController.document) if @bookController.document.hasIssues?
    @items.empty? ? showNoIssuesImage : showIssuesView
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
    object = @outlineView.itemAtRow(@outlineView.selectedRow)
    return unless object
    if object.class == Item
      @bookController.tabViewController.addObject(object)
    elsif object.class == Issue
      parent = @outlineView.parentForItem(object)
      if parent && parent.class == Item
        @bookController.tabViewController.addObject(parent)
        @bookController.tabViewController.showTextView
        if object.lineNumber
          @bookController.textViewController.selectLineNumber(object.lineNumber + 1)
        end
      end
    end
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:object)
    cell.font = NSFont.systemFontOfSize(11.0)
    if object.class == Item
      cell.badgeCount = object.issues.size
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(object.name))
    elsif object.class == Book
      cell.badgeCount = object.issues.size
      cell.image = NSImage.imageNamed('book.png')
    else
      cell.badgeCount = nil
      cell.image = NSImage.imageNamed('wrench.png')
    end
  end

end
