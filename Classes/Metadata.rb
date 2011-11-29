class Metadata

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :sortCreator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights, :cover
  
  def self.deriveSortCreator(creator)
    parts = creator.split
    case parts.size
    when 0
      derivedSortCreator = ''
    when 1
      derivedSortCreator = parts[-1]
    else
      derivedSortCreator = parts[-1] + ', ' + parts[0...-1].join(' ')
    end
    derivedSortCreator
  end
  
  def initialize(book=nil)
    # provide some default values
    @title = "untitled"
    @language = "en"
    @identifier = UUID.create
    @date = Time.now.strftime("%Y-%m-%d")
        
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
  
  def sortCreator
    if @sortCreator.blank? && !@creator.blank?
      @sortCreator = Metadata.deriveSortCreator(@creator)
    end
    @sortCreator
  end
  
  private
  
  def updateAttrbute(element)
    method = element.name.to_sym
    self.class.send(:attr_accessor, method) unless self.respond_to?(method)
    self.send("#{method}=", element.text)
  end
  
end