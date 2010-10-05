class AppController
  
  attr_accessor :bookController
  
  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end
  
  def applicationShouldTerminate(application)
    puts "applicationShouldTerminate"
    @bookController.closeBook(self)
  end
  
  def applicationWillTerminate(notification)
    puts "applicationWillTerminate"
    # @bookController.closeBook(self)
  end

end
