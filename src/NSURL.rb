class NSURL
  def remote?
    scheme != 'file'
  end  
end