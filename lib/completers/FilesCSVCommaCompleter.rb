###################
### DEPRECATED - this class remains purely for legacy purposes
### instead, use an ordinary FilesCompleter and specify comma as its separator in your yaml like this: "<Files>, "
### this completer is for completing one or more local file paths separated by a comma
###################
require_relative 'FilesCompleter.rb'


class FilesCSVCommaCompleter < FilesCompleter

  def separator(rawChoice)
    ','
  end

end


