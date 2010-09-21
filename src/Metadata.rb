class Metadata
  
  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights

  def initialize(book)
    book.container.opfDoc.elements.each("/package/metadata/*") do |e|
      case e.name
      when 'title'
        @title = e.text
      when 'publisher'
        @publisher = e.text
      when 'creator'
        @creator = e.text
      when 'date'
        @date = e.text
      when 'language'
        @language = e.text
      when 'description'
        @description = e.text
      when 'rights'
        @rights = e.text
      when 'identifier'
        @identifier = e.text
      when 'subject'
        @subject = e.text
      else
        # TODO dynamically add attirbutes
        puts "Unparsed metadata element: #{e}" unless e.name.strip.empty?
      end
    end
  end
  
end