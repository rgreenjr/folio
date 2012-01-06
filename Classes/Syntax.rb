class Syntax
  
  STRING_TYPE        = "StringType"
  TAG_TYPE           = "TagType"
  KEYWORD_TYPE       = "KeywordType"
  COMMENT_TYPE       = "CommentType"
  BLOCK_COMMENT_TYPE = "BlockCommentType"
  
  attr_accessor :type
  attr_accessor :tags
  attr_accessor :strings
  attr_accessor :keywords
  attr_accessor :comments
  attr_accessor :blockComments
  
  def self.sharedInstance
    @sharedInstance ||= self.new
  end
  
end