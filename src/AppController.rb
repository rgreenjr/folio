class AppController

  def applicationShouldOpenUntitledFile(application)
    recentURLs = NSDocumentController.sharedDocumentController.recentDocumentURLs
    unless recentURLs.empty?
      url = recentURLs.first
      if File.exists?(url.path)
        if NSDocumentController.sharedDocumentController.openDocumentWithContentsOfURL(url, display:true, error:nil)
          return false
        end
      end
    end
    true
  end

end
