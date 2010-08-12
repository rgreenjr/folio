class Package

  def self.parse(opf_filepath)
  
  end
  
  def self.generateOPF(book, filepath)
    File.new(filepath, "w")
    File.open(filepath, "w") do |f|
      f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      f.puts "<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookID\" version=\"2.0\">"
      f.puts "  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:opf=\"http://www.idpf.org/2007/opf\">"
      f.puts "    <dc:title>#{book.title}</dc:title>"
      f.puts "    <dc:creator opf:role=\"aut\">#{book.author}</dc:creator>"
      f.puts "    <dc:description>#{book.description}</dc:description>"
      f.puts "    <dc:publisher>#{book.publisher}</dc:publisher>"
      f.puts "    <dc:language>#{book.language}</dc:language>"
      f.puts "    <dc:identifier id=\"BookID\" opf:scheme=\"UUID\">#{book.identifier}</dc:identifier>"
      f.puts "  </metadata>"
      f.puts "  <manifest>"
      entries.each do |entry|
        if entry.id && entry.manifestable?
          f.puts "    <item id=\"#{entry.id}\" href=\"#{entry.href}\" media-type=\"#{entry.mediaType}\"/>"
          FileUtils.mkdir_p(File.dirname("#{book.tmp}/#{entry.href}"))
          FileUtils.cp("#{book.root}/#{entry.href}", "#{book.tmp}/#{entry.href}")
        end
      end
      f.puts "  </manifest>"
      f.puts "  <spine toc=\"ncx\">"
      spine.each do |entry|
        f.puts "    <itemref idref=\"#{entry.id}\"/>"
      end
      f.puts "  </spine>"
      f.puts "  </package>"
    end
  end

end