class Guide < DelegateClass(Array)

  TYPE_HASH = {
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
    TYPE_HASH.values.sort
  end

  def self.code_for(name)
    TYPE_HASH.key(name)
  end

  def self.name_for(code)
    TYPE_HASH[code]
  end
  
  def initialize(book=nil)
    @itemRefs = []
    super(@itemRefs)
    # if book
    #   book.container.opfDoc.elements.each("/package/guide/reference") do |element|
    #     href  = element.attributes["href"]
    #     item  = book.manifest.itemWithHref(href)
    #     raise "Guide item with href \"#{href}\" could not be found." unless item
    #     item.referenceType = element.attributes["type"]
    #     item.referenceTitle = element.attributes["title"]
    #   end
    # end
  end
  
end
