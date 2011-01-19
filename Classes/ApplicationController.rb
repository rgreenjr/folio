class ApplicationController
  
  # Attempts to open most recent document, otherwise returns true.
  def applicationShouldOpenUntitledFile(application)
    controller = NSDocumentController.sharedDocumentController
    recentURLs = controller.recentDocumentURLs
    unless recentURLs.empty?
      url = recentURLs.first
      if File.exists?(url.path)
        if controller.openDocumentWithContentsOfURL(url, display:true, error:Pointer.new(:id))
          return false
        end
      end
    end
    true
  end

  # Loads PreferencesController and orders its window front.
  def showPreferencesWindow(sender)
    @preferencesController ||= PreferencesController.alloc.init
    @preferencesController.window
    @preferencesController.showWindow
  end

  # Returns the folder used to store application related support files.
  def applicationSupportFolder
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    basePath = paths.size > 0 ? paths[0] : NSTemporaryDirectory()
    File.join(basePath, applicationName)
  end

  # Returns application's name. 
  def applicationName
    NSBundle.mainBundle.infoDictionary["CFBundleName"]
  end
  
end
