class SpineController

  attr_accessor :spine, :tableView, :webView, :textView

  def awakeFromNib
    @tableView.delegate = self
    @tableView.dataSource = self
    @textView.delegate = self
    @tableView.reloadData
  end

  def spine=(spine)
    @spine = spine
    @tableView.reloadData
  end

  def numberOfRowsInTableView(aTableView)
    @spine ? @spine.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @spine[index].name
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    item = @spine[@tableView.selectedRow]
    @webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(item.uri)))
    string = NSAttributedString.alloc.initWithString(item.content)
    @textView.textStorage.attributedString = string
    @textView.richText = false
  end

  def textDidChange(notification)
    item = @spine[@tableView.selectedRow]
    item.content = @textView.textStorage.string
    @webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(item.uri)))
  end

end