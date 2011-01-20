class Validator

  def self.validate(book)
    libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")    
    command = "cd \"#{libDir}\"; java -jar epubcheck-1.1.jar \"#{book.fileURL.path}\""
    puts command
    result = `#{command} 2>&1`
    result = result.gsub(book.fileURL.path + '/', '')
    result
  end

end



