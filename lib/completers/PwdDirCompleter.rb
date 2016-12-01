#############
### matches dirs from the pwd
#############

class PwdDirCompleter < DynamicCompleter

  def deriveChoices(choice, token)
    Dir.pwd.sub(/^\//, '').split('/').map { |s| "#{s} " }
  end

end


