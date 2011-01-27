class Metadata

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :sortCreator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights, :cover
  
  def initialize(book=nil)
    # provide default values for three required metadata attributes
    @title = "untitled"
    @language = "en"
    @identifier = UUID.create
    
    if book
      book.container.opfDoc.elements.each("/package/metadata/*") do |element|
        case element.name
        when "meta"
          if element.attributes["name"] == "cover"
            @cover = book.manifest.itemWithId(element.attributes["content"])
          else
            puts "Ignoring metadata element: #{element}"
          end
        when "creator"
          @sortCreator = element.attributes["opf:file-as"]
          updateAttrbute(element)
        else
          updateAttrbute(element)
        end
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