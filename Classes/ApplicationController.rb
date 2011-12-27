class ApplicationController
  
  # Attempts to open most recent document, otherwise returns true.
  def applicationShouldOpenUntitledFile(application)
    controller = NSDocumentController.sharedDocumentController
    recentURLs = controller.recentDocumentURLs
    unless recentURLs.empty?
      url = recentURLs.first
      if File.exists?(url.path)
        error = Pointer.new(:id)
        if controller.openDocumentWithContentsOfURL(url, display:true, error:error)
          return false
        else
          NSApplication.sharedApplication.presentError(error[0]) if error[0]
        end
      end
    end
    true
  end

  # Loads PreferencesController and orders its window front.
  def showPreferencesWindow(sender)
    PreferencesController.sharedPreferencesController.showWindow(sender)
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
