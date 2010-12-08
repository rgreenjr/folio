class Metadata

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights, :cover
  
  def initialize(book)
    book.container.opfDoc.elements.each("/package/metadata/*") do |e|
      if e.name == "meta"
        if e.attributes["name"] == "cover"
          @cover = book.manifest.itemWithId(e.attributes["content"])
        end
      else
        method = e.name.to_sym
        self.class.send(:attr_accessor, method) unless self.respond_to?(method)
        self.send("#{method}=", e.text)
      end
    end  
  end

end