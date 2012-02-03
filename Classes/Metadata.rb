class Metadata

  SUBJECTS = [
    "Action & Adventure",
    "African American",
    "Art & Architecture",
    "Arts & Entertainment",
    "Astronomy",
    "Biography",
    "Biography & Memoir",
    "Business",
    "Business & Personal Finance",
    "Careers",
    "Chemistry",
    "Children & Teens",
    "Classics",
    "Comedy",
    "Computers & Internet",
    "Contemporary",
    "Cooking",
    "Cookbooks, Food & Wine",
    "Current Events",
    "Design",
    "Earth Sciences",
    "Economics",
    "Education",
    "Engineering",
    "Erotica",
    "Family & Relationship",
    "Fantasy",
    "Fiction",
    "Fiction & Literature",
    "Finance",
    "Food & Wine",
    "Games",
    "Gay",
    "Ghost",
    "Health",
    "Health, Mind & Body",
    "History",
    "Humor",
    "Industries & Professions",
    "Investing",
    "Law",
    "Life Sciences",
    "Lifestyle",
    "Lifestyle & Home",
    "Literature",
    "Literary Criticism",
    "Management",
    "Management & Leadership",
    "Marketing",
    "Marketing & Sales",
    "Mathematics",
    "Medical",
    "Music",
    "Mysteries",
    "Mysteries & Thrillers",
    "Nature",
    "Nonfiction",
    "Parenting",
    "Performing Arts",
    "Personal Finance",
    "Philosophy",
    "Photography",
    "Physics",
    "Poetry",
    "Politics",
    "Politics & Current Events",
    "Professional & Technical",
    "Psychology",
    "Reference",
    "Religious",
    "Romance",
    "Sci-Fi & Fantasy",
    "Science",
    "Science & Nature",
    "Science Fiction",
    "Self-Improvement",
    "Short Stories",
    "Small Business & Entrepreneurship",
    "Social Science",
    "Spirituality",
    "Sports",
    "Sports & Outdoors",
    "Suspense",
    "Technology",
    "Theater",
    "Transportation",
    "Travel",
    "Travel & Adventure",
    "Western",
    "Young Adult"
  ]
  
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

  def self.subjects
    @subjects ||= SUBJECTS.sort
  end

  def self.closestSubject(string)
    self.subjects.find {|subject| subject.match(/^#{string}/i)}
  end

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
    @title = "Untitled"
    @language = "en"
    @identifier = UUID.create
    @date = Time.now.strftime("%Y-%m-%d")
        
    if book
      book.container.each_element("/package/metadata/*") do |element|
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
  
  def validate(issues)
    issues << Issue.new("Metadata title cannot be blank.") if @title.blank?
    issues << Issue.new("Metadata language cannot be blank.") if @language.blank?
    issues << Issue.new("Metadata identifier cannot be blank.") if @identifier.blank?    
    unless @date.blank? || @date =~ /^(\d{4}|\d{4}-\d{2}|\d{4}-\d{2}-\d{2})$/
      issues << Issue.new("Metadata date must be in the form YYYY, YYYY-MM or YYYY-MM-DD (e.g., \"2011\", \"2011-05\", or \"2011-05-01\")")
    end
  end
  
  private
  
  def updateAttrbute(element)
    method = element.name.to_sym
    self.class.send(:attr_accessor, method) unless self.respond_to?(method)
    self.send("#{method}=", element.text)
  end
  
end