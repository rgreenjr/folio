class Kernel

  def pluralize(count, singular, plural=nil)
    number = count.to_i
    if number == 1
      "#{number} #{singular}"
    else
      plural ? "#{number} #{plural}" : "#{number} #{singular}s"
    end
  end

end
