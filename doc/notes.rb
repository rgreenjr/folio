TODO
====

- Tracked edited state for book
- Navigation: add points
- Spine: add items
- Outline undo
- ePub validation
- add webview forward/backward bunttons
- Metadata assignments (marks as TOC, prefaces, etc)
- Move to NSDocument model
- auto scroll source view on navigation changes
- TabViewController redesign
- Guide generation
- Drag to desktop
- Fix last tab drawing bug

Hpricot Examples
===============

%w{body p h1 h2 h3 div blockquote span a sup}.each do |element|
  doc.search("//#{element}").remove_attr('class')
  doc.search("//#{element}").remove_attr('style')
end

Zip Examples
============

def self.open(filepath)
	Zip::ZipInputStream::open(filepath) do |io|
		while (entry = io.get_next_entry)
		  puts "Contents of #{entry.name}:"
		  if entry.name =~ /opf$/
			return self.event_parse(io.read)
		  end
		end
	end
end

def save
	Zip::ZipFile.open("/Users/rgreen/Desktop/foo.zip", Zip::ZipFile::CREATE) do |zip|
		zip.get_output_stream("first.txt") { |f| f.puts "Hello from ZipFile" }
		zip.mkdir("a_dir")
	end
end
