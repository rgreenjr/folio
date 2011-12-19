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

  def self.types
    REFERENCE_TYPE_HASH.values.sort
  end

  def self.type_for(title)
    REFERENCE_TYPE_HASH.key(title)
  end

  def self.title_for(type)
    REFERENCE_TYPE_HASH[type]
  end
  
  def initialize(container, manifest)
    @manifest = manifest
    container.each_element("/package/guide/reference") do |element|
      href  = element.attributes["href"]
      item  = @manifest.itemWithHref(href)
      raise "Guide reference item with href \"#{href}\" could not be found." unless item
      item.referenceType = element.attributes["type"]
      item.referenceTitle = element.attributes["title"]
    end
  end
  
  def each
    @manifest.each do |item|
      yield item if item.referenceType && item.referenceTitle
    end
  end
  
end
