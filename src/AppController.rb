class AppController
  
  # def applicationDidFinishLaunching(notification)
  #   if @filename
  #     @bookWindowController.openBook(@filename)
  #   else
  #     @bookWindowController.openBook(Bundle.path("The Fall of the Roman Empire_ A New History of Rome and the Barbarians", "epub"))
  #   end
  # end

  def applicationShouldTerminate(application)
    puts "applicationShouldTerminate"
    true
  end
  
end
