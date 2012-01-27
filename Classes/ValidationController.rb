class ValidationController < NSWindowController

  attr_accessor :progressBar
  attr_accessor :progressText
  attr_accessor :successWindow

  def init
    initWithWindowNibName("Validation")
  end
  
  def validateBook(book, lineNumberView)
    # force validated window to load
    window

    # clear any existing issues
    book.clearIssues
    
    showStatus(book)
    
    updateStatus("Validating OPF file", 5)
    book.validateOPF

    updateStatus("Validating container", 20)
    book.validateContainer
    
    updateStatus("Validating metadata", 20)
    book.validateMetadata

    updateStatus("Validating manifest", 50)
    book.validateManifest
    
    updateStatus("Validating navigation", 80)
    book.validateNavigation

    updateStatus("Complete", 90)
    updateStatus("Complete", 95)
    updateStatus("Complete", 100)
    
    hideStatus
    
    showSuccessWindow(book) if book.totalIssueCount == 0
  end

  def validateBook_OLD(book, lineNumberView)
    unless javaRuntimeInstalled?
      Alert.runModal(book.controller.window, "A Java runtime is required to validate this book.")
      return false
    end
    
    # force validated window to load
    window

    # clear any existing issues
    book.clearIssues

    begin
      showStatus(book)

      # set the path to the epubcheck library
      libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")

      # construct the system command
      command = "cd \"#{libDir}\"; java -jar epubcheck-1.2.jar \"#{book.fileURL.path}\""

      # create a file to hold validation output
      resultFile = Tempfile.new('com.folioapp.validation-')

      # run the validation command and piping all output to resultFile
      system("#{command} &>#{resultFile.path}")

      # keep count of number of validation issues found
      counter = 1

      # process each line of the resultFile
      File.readlines(resultFile.path).each do |line|

        # stop if there are more than 10000 validation issues
        break if counter > 100000

        parseLine(book, line)

        # increment the number of issues processed
        counter += 1
      end

    ensure
      hideStatus
    end

    showSuccessWindow(book) if book.totalIssueCount == 0
    
    true
  end

  private
  
  def showStatus(book)
    # show the validation status window
    NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
    
    # necessary since we're running in a background thread
    window.makeKeyAndOrderFront(nil)
    
    # start progress bar animation
    @progressBar.usesThreadedAnimation = true
    @progressBar.startAnimation(self)
  end
  
  def hideStatus
    # end window sheet session
    NSApp.endSheet(window)
    
    # hide the window
    window.orderOut(self)
    
    # stop progress bar animation
    @progressBar.stopAnimation(self)
  end

  def updateStatus(status, amount)
    @progressText.stringValue = status
    @progressBar.doubleValue = amount
  end
  
  def showSuccessWindow(book)
    NSApp.beginSheet(successWindow, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)
    sleep(2)
    performSelectorOnMainThread(:hideSuccessWindow, withObject:nil, waitUntilDone:false)
  end
  
  def hideSuccessWindow
    NSApp.endSheet(successWindow)
    successWindow.orderOut(nil)
  end

  def parseLine(book, line)
    if line =~ /^ERROR/
      parseError(book, line)
    elsif line =~ /^WARNING/
      parseWarning(book, line)
    else
      # log unknown validation message
      # puts "*** Validation.validateBook ignoring message: #{line}"
    end
  end

  def parseError(book, line)
    # strip prefix path information from each error
    line.gsub!(File.join(book.fileURL.path, book.container.relativePath, '/'), '')

    if line =~ /^ERROR: (.*)\(([0-9]+)\): (.*)/

      # create a new maker with the message and line number
      issue = Issue.new($3, $2.to_i - 1)

      # get relative path of item
      itemHref = $1
      
    elsif line =~ /^ERROR: (.*): (.*)/

      # error doesn't include a line number so create new issue without one
      issue = Issue.new($2)

      # get relative path of item
      itemHref = $1

    else
      # create new issue with entire message since parsing failed
      issue = Issue.new(line)
    end

    if itemHref

      # get item at itemHref
      item = book.manifest.itemWithHref(itemHref)

      if item
        # add the new issue to associated item
        item.addIssue(issue)
      else
        # item wasn't found in manifest
        issue.message = "Auto-generated metadata file \"#{itemHref}\", line #{issue.lineNumber}: " + issue.message
        issue.lineNumber = nil
        book.addIssue(issue)        
      end
    else
      # add issue to book since there isn't an associated item
      book.addIssue(issue)
    end
  end

  def parseWarning(book, line)
    puts "parseWarning => #{line}"
    if line =~ /^WARNING: .*: item \((.*)\) (.*)/
      # create new issue with parsed message
      issue = Issue.new("#{$1} #{$2}")
    else
      # create new issue with entire message since parsing failed
      issue = Issue.new(line)
    end

    # add issue to book since there isn't an associated item
    book.addIssue(issue)
  end
  
  # return true if a java runtime is installed
  def javaRuntimeInstalled?
    `which java` != ''
  end
  
end
