class Validator

  def self.validate(book, lineNumberView)
    libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")    
    command = "cd \"#{libDir}\"; java -jar epubcheck-1.1.jar \"#{book.fileURL.path}\""
    puts command
    result = `#{command} 2>&1`
    result = result.gsub(book.fileURL.path + '/', '')
    result.each_line do |line|
      if line =~ /^ERROR: (.*)\(([0-9]+)\): (.*)/
        itemHref = $1
        lineNumber = $2.to_i - 1
        message = $3
        
        item = book.manifest.itemWithHref(itemHref)
        
        puts itemHref
        puts lineNumber
        puts message

        if item
          marker = LineNumberMarker.alloc.initWithRulerView(lineNumberView, lineNumber:lineNumber, message:message)
          item.addMarker(marker)
        else
          puts "*** Cannot find item"
        end

        puts '============='
        
      end      
    end
  end

end



