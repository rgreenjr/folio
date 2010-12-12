class AppController
  
  attr_accessor :bookController
  
  def application(app, openFile:filename)
    @filename = filename
  end
  
  def applicationDidFinishLaunching(notification)
    if @filename
      @bookController.openBook(@filename)
    else
      @bookController.openBook(Bundle.path("The Fall of the Roman Empire_ A New History of Rome and the Barbarians", "epub"))
    end
  end
  
  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end
  
  def applicationShouldTerminate(application)
    @bookController.closeBook(self)
  end
  
end
