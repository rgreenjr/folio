class Syntax
  
  STRING_TYPE        = "StringType"
  TAG_TYPE           = "TagType"
  KEYWORD_TYPE       = "KeywordType"
  COMMENT_TYPE       = "CommentType"
  BLOCK_COMMENT_TYPE = "BlockCommentType"
  
  def self.defaultInstance
    @defaultInstance ||= []
  end
  
end