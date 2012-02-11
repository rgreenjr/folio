class IssueViewController < NSViewController

  attr_reader   :bookController
  attr_accessor :outlineView
  attr_accessor :noIssuesImageView
  attr_accessor :statusTextField

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
    
    # emboss status message text
    @statusTextField.cell.backgroundStyle = NSBackgroundStyleRaised

    # set single click target and action
    @outlineView.target = self
    @outlineView.action = "displayCurrentSelection:"

    # receive notification when item issues are updated 
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"itemIssuesDidChange:", name:"ItemIssuesDidChange", object:@bookController)

    # show default image
    showNoIssuesImage
  end
  
  def visible?
    view && !view.hidden? && !view.superview.nil?
  end

  def refresh
    # update statusTextField
    @statusTextField.stringValue = "Validation Issue".pluralize(@bookController.document.totalIssueCount)    

    # get all items with validation issues
    @items = @bookController.document.container.package.manifest.itemsWithIssues
    
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
      object.container.package.metadata.title
    else
      object.to_s
    end
  end
  
  def outlineViewSelectionDidChange(notification)
    displayCurrentSelection(self)
  end
  
  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:object)
    cell.font = NSFont.systemFontOfSize(11.0)
    if object.class == Item
      cell.badgeCount = nil
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(object.name))
    elsif object.class == Book
      cell.badgeCount = nil
      cell.image = NSImage.imageNamed('book.png')
    else
      cell.badgeCount = nil
      cell.image = nil
    end
  end

  def selectPreviousIssue(sender)
    @outlineView.selectRow(@outlineView.selectedRow - 1)    
  end

  def selectNextIssue(sender)
    @outlineView.selectRow(@outlineView.selectedRow + 1)    
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
        @bookController.tabbedViewController.ensureSourceViewVisible
        if object.lineNumber
          @bookController.tabbedViewController.sourceViewController.selectLineNumber(object.lineNumber)
        end
      end
    end
  end

end
