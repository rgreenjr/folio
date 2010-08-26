class ManifestController

  attr_accessor :manifest, :tableView, :webView, :textView

	def awakeFromNib
    @tableView.delegate = self
    @tableView.dataSource = self
    @tableView.reloadData
	end

	def manifest=(manifest)
	  @manifest = manifest
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    @manifest ? @manifest.size : 0
  end
  
  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @manifest[index].name
  end
  
  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    item = @manifest[@tableView.selectedRow]
    webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(item.url.to_s)))
  end
  
end
