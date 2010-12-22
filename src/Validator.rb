class Validator

  def self.validate(book)
    tmpdir = Dir.mktmpdir("folio-validation-")
    epub_filepath = "#{tmpdir}/#{book.basename}"
    book.saveAs(epub_filepath)
    
    prefix = "#{NSBundle.mainBundle.bundlePath}/Contents/Resources/lib/epubcheck"
    lib_path = "#{prefix}/lib/saxon.jar:#{prefix}/lib/jigsaw.jar"
    jar_path = "#{prefix}/epubcheck-1.1.jar"
    
    result = `java -jar "#{jar_path}" -classpath "#{lib_path}" "#{epub_filepath}" 2>&1`

    result = result.gsub(epub_filepath, '')
    
    puts result
    FileUtils.rm_rf(tmpdir)
    result
  end

end
