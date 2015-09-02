###################
### this completer is for completing one or more local file paths separated by a comma
###################
require_relative 'FilesCompleter.rb'


class FilesCSVCommaCompleter < FilesCompleter

  def separator
    ','
  end

end


