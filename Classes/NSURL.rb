class NSURL
  def remote?
    scheme != nil && scheme != 'file'
  end  
end
