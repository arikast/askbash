#!/usr/bin/ruby

################################
### the entry point which bash will call 
### see the README.md for full instructions how to setup
################################


require_relative 'lib/core.rb'
require_relative 'lib/config-search.rb'

include ConfigSearch

begin
    config = ARGV[0]
    #config = completionConfSearch( COMPLETION_CONF_DIRS )

    log "attempting completion for #{ENV['COMP_LINE']}"
    log "using config #{config}"

    ac = AutoCompleter.new(config, ENV["COMP_LINE"])

    answer = ac.parse
    log "returned #{answer}"
    puts answer

rescue StandardError => e
    if debugMode?
        raise e
    else
        log "problem autocompleting: #{e}"
        log e.backtrace
    end
end
