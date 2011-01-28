class ValidationController < NSWindowController

  attr_accessor :progressBar, :progressText

  def init
    initWithWindowNibName("Validation")
  end

  def validateBook(book, lineNumberView)
    # force validated window to load
    window

    # create an array to hold items with validation errors
    items = []

    # clear any existing markers
    book.clearMarkers

    begin
      # start the progress bar animation
      @progressBar.usesThreadedAnimation = true
      @progressBar.startAnimation(self)

      # show the validation status window
      NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)

      # set the path to the epubcheck library
      libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")

      # construct the system command
      command = "cd \"#{libDir}\"; java -jar epubcheck-1.1.jar \"#{book.fileURL.path}\""

      # create a file to hold validation output
      resultFile = Tempfile.new('folio-validation-')

      # run the validation command and piping all output to resultFile
      system("#{command} &>#{resultFile.path}")

      # keep count of number of validation issues found
      counter = 1

      # process each line of the resultFile
      File.readlines(resultFile.path).each do |line|

        # stop if there are more than 10000 validation issues
        break if counter > 100000

        # strip prefix path information from each error
        line.gsub!(File.join(book.fileURL.path, book.container.relativePath, '/'), '')

        if line =~ /^ERROR: (.*)\(([0-9]+)\): (.*)/
          # get relative path of item
          itemHref = $1

          # get line of validation issue
          lineNumber = $2.to_i - 1

          # get validation message
          message = $3

          # look up the associated item
          item = book.manifest.itemWithHref(itemHref)

          if item
            # create a new maker with the validation info
            marker = LineNumberMarker.alloc.initWithRulerView(lineNumberView, lineNumber:lineNumber, message:message)

            # add the new marker to the item
            item.addMarker(marker)

            # add the item to the list of items with validation issues
            items << item unless items.include? item
          else
            # log that the associated item could not be found
            puts "*** Validation.validateBook could not find item: #{itemHref}"

            # log the validation message
            puts line
          end

          counter += 1
        else
          # log non-error validation message
          puts "*** Validation.validateBook ignoring message: #{line}"
        end
      end

    ensure
      # end window sheet session
      NSApp.endSheet(window)

      # hide the window
      window.orderOut(self)

      # stop progress bar animation
      @progressBar.stopAnimation(self)
    end
  end

end
