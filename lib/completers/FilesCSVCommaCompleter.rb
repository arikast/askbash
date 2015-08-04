###################
### this completer is for completing a local file path
###################
require_relative 'FilesCompleter.rb'


class FilesCSVCommaCompleter < FilesCompleter

  def separator
    ','
  end

end


