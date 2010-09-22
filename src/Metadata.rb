class Metadata

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights
  
  def initialize(book)
    book.container.opfDoc.elements.each("/package/metadata/*") do |e|
      method = e.name.to_sym
      unless self.respond_to?(method)
        self.class.send(:attr_accessor, method)
      end
      self.send("#{method}=", e.text)
    end  
  end
  
end