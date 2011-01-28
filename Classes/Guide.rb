class Guide

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
    @items = []
  end

  def size
    @items.size
  end

  def [](index)
    @items[index]
  end

  def each(&block)
    @items.each(&block)
  end

  def <<(item)
    @items << item
  end
  
end
