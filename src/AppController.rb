class AppController
  
  attr_accessor :bookController
  
  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end
  
  def applicationShouldTerminate(application)
    @bookController.closeBook(self)
  end
  
end
