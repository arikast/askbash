#!/usr/bin/ruby

################################################
### this generates entries to put in your .bashrc
### see the README.md for instructions on the easiest way to incorporate its output in your .bashrc or .bash_profile
################################################


require_relative 'lib/core.rb'
require_relative 'lib/config-search.rb'

include ConfigSearch

allconfs = allCompletionConfs( COMPLETION_CONF_DIRS )

allconfs.each {|conf|
    #puts "complete -C \"$ASKBASH_HOME/askbash.rb\" -o nospace #{conf.command}"
    puts "complete -C \"$ASKBASH_HOME/askbash.rb #{conf.configfile}\" -o nospace #{conf.command}"
}

#puts allconfs

