class Numeric
  def to_storage_size
    if self > 0
      units = [" bytes", " KB", " MB", " GB", " TB"]
      e = (Math.log(self) / Math.log(1024)).floor
      s = "%.2f" % (self.to_f / 1024**e)
      s.sub(/\.?0*$/, units[e])
    else
      "0 bytes"
    end
  end
end