class Metadata

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :sortCreator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights, :cover
  
  def initialize(book=nil)
    @title = 'untitled'
    @language = 'en'
    return unless book
    book.container.opfDoc.elements.each("/package/metadata/*") do |e|
      case e.name
      when "meta"
        if e.attributes["name"] == "cover"
          @cover = book.manifest.itemWithId(e.attributes["content"])
        end
      when "creator"
        @sortCreator = e.attributes["opf:file-as"]
        updateAttrbute(e)
      else
        updateAttrbute(e)
      end
    end  
  end
  
  private
  
  def updateAttrbute(element)
    method = element.name.to_sym
    self.class.send(:attr_accessor, method) unless self.respond_to?(method)
    self.send("#{method}=", element.text)
  end
  
end