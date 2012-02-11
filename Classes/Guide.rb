class Guide

  REFERENCE_TYPE_HASH = {
    "acknowledgements" => "Acknowledgements",
    "colophon"         => "Colophon",
    "copyright-page"   => "Copyright Page",
    "cover"            => "Cover",
    "dedication"       => "Dedication",
    "epigraph"         => "Epigraph",
    "foreword"         => "Forward",
    "index"            => "Index",
    "loi"              => "List of Illustrations",
    "lot"              => "List of Tables",
    "notes"            => "Notes",
    "preface"          => "Preface",
    "text"             => "Text",
    "title-page"       => "Title Page",
    "toc"              => "Table of Contents",
  }

  def self.load(package)
    guide = Guide.new(package)
    package.each("guide/reference") do |element|
      href  = element.attributes["href"]      
      href, fragment = href.split('#') # strip fragment before lookup
      item  = package.manifest.itemWithHref(href)
      if item
        item.referenceType = element.attributes["type"]
        item.referenceTitle = element.attributes["title"]
      else
        # raise "Guide reference item with href \"#{href}\" could not be found." unless item
        puts "Folio: ignoring guide reference not declared in manifest \"#{href}\""
      end
    end
    guide
  end
  
  def self.types
    REFERENCE_TYPE_HASH.values.sort
  end

  def self.type_for(title)
    REFERENCE_TYPE_HASH.key(title)
  end

  def self.title_for(type)
    REFERENCE_TYPE_HASH[type]
  end
  
  def initialize(package)
    @package = package
  end
  
  def each
    @package.manifest.each do |item|
      yield item if item.referenceType && item.referenceTitle
    end
  end
  
end
