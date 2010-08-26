class SpineController
  
  attr_accessor :spine, :tableView, :webView, :textView

	def awakeFromNib
    @tableView.delegate = self
    @tableView.dataSource = self
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
    webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(item.url.to_s)))
  end
  
end