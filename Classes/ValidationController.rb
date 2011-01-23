class ValidationController < NSWindowController

  attr_accessor :progressBar, :progressText

  def init
    initWithWindowNibName("Validation")
  end

  def validateBook(book, lineNumberView)
    window # force window to load
    items = []
    clearValidationMarkers(book)
    begin
      @progressBar.usesThreadedAnimation = true
      @progressBar.startAnimation(self)
      NSApp.beginSheet(window, modalForWindow:book.controller.window, modalDelegate:self, didEndSelector:nil, contextInfo:nil)

      libDir  = File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/lib/epubcheck/")
      command = "cd \"#{libDir}\"; java -jar epubcheck-1.1.jar \"#{book.fileURL.path}\""
      resultFile = Tempfile.new('folio-validation-')
      # puts command
      system("#{command} &>#{resultFile.path}")

      counter = 1
      File.readlines(resultFile.path).each do |line|
        break if counter > 100000

        line.gsub!(File.join(book.fileURL.path, book.container.relativePath, '/'), '')

        if line =~ /^ERROR: (.*)\(([0-9]+)\): (.*)/
          itemHref = $1
          lineNumber = $2.to_i - 1
          message = $3

          item = book.manifest.itemWithHref(itemHref)

          # puts itemHref
          # puts lineNumber
          # puts message

          if item
            marker = LineNumberMarker.alloc.initWithRulerView(lineNumberView, lineNumber:lineNumber, message:message)
            item.addMarker(marker)
            unless items.include? item
              items << item
            end
          else
            puts "*** Validation.validateBook could not find item: #{itemHref}"
          end

          counter += 1
        else
          puts "*** Validation.validateBook ignoring message: #{line}"
        end
      end

    ensure
      NSApp.endSheet(window)
      window.orderOut(self)
      @progressBar.stopAnimation(self)
    end
  end

  private

  def clearValidationMarkers(book)
    book.manifest.each do |item|
      item.clearMarkers
    end
  end

end



