class Validator

  def self.validate(book)
    tmpdir = Dir.mktmpdir("folio-validation-")
    epubFilepath = File.join(tmpdir, "book.epub")
    epubFilepath = "/Users/rgreen/Downloads/The Shallows_ What the Internet is Doing to Our Brains.epub"
    
    puts epubFilepath
    
    # `open #{tmpdir}`    
    # error = Pointer.new(:id)
    # book.writeToURL(epubFilepath, ofType:nil, error:error)

    libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")    
    command = "cd \"#{libDir}\"; java -jar epubcheck-1.1.jar \"#{epubFilepath}\""
    puts command
    result = `#{command} 2>&1`
    result = result.gsub(epubFilepath, '')
    FileUtils.rm_rf(tmpdir)
    result
  end

end



