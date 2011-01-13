class AppController

  def applicationShouldOpenUntitledFile(application)
    controller = NSDocumentController.sharedDocumentController
    recentURLs = controller.recentDocumentURLs
    unless recentURLs.empty?
      url = recentURLs.first
      if File.exists?(url.path)
        if controller.openDocumentWithContentsOfURL(url, display:true, error:nil)
          return false
        end
      end
    end
    true
  end

end
