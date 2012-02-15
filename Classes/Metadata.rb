class Metadata

  attr_accessor :title
  attr_accessor :language
  attr_accessor :identifier
  attr_accessor :creator
  attr_accessor :sortCreator
  attr_accessor :contributor
  attr_accessor :publisher
  attr_accessor :subject
  attr_accessor :description
  attr_accessor :date
  attr_accessor :type
  attr_accessor :format
  attr_accessor :source
  attr_accessor :relation
  attr_accessor :coverage
  attr_accessor :rights
  attr_accessor :cover
  attr_reader   :issues

  def self.load(package)
    metadata = Metadata.new
    package.each("metadata/*") do |element|
      case element.name
      when "meta"
        if element.attributes["name"] == "cover"
          metadata.cover = package.manifest.itemWithId(element.attributes["content"])
        else
          puts "Folio: ignoring metadata element \"#{element}\""
        end
      when "creator"
        metadata.sortCreator = element.attributes["opf:file-as"]
        metadata.updateAttrbute(element)
      else
        metadata.updateAttrbute(element)
      end
    end
    metadata
  end

  def initialize
    @title = "untitled"
    @language = Language.defaultLanguage
    @identifier = UUID.create
    @date = Time.now.strftime("%Y-%m-%d")
  end

  def validate(issues)
    issues << Issue.new("Metadata title cannot be blank.") if @title.blank?
    issues << Issue.new("Metadata language cannot be blank.") if @language.blank?
    issues << Issue.new("Metadata identifier cannot be blank.") if @identifier.blank?    
    unless @date.blank? || @date =~ /^(\d{4}|\d{4}-\d{2}|\d{4}-\d{2}-\d{2})$/
      issues << Issue.new("Metadata date must be in the form YYYY, YYYY-MM or YYYY-MM-DD (e.g., \"2011\", \"2011-05\", or \"2011-05-01\")")
    end
  end

  def updateAttrbute(element)
    method = element.name.to_sym
    self.class.send(:attr_accessor, method) unless self.respond_to?(method)
    self.send("#{method}=", element.text)
  end

end