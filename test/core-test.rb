#!/usr/bin/ruby

# for use with bash autocompletion
#
# to setup, run this in bash:
# ./askbash.bash
#
# then to use: mycmdtotriggercompletion [tab]
#
# to enable debug logging, run this in your shell to write debug stmts to askbash.log:
# export ASKBASH_DEBUG=1
# to include line numbers use this:
# export ASKBASH_DEBUG=2


require_relative '../lib/core.rb'
require_relative '../lib/testtools.rb'

ENV["ASKBASH_DEBUG"] = "1"

@config = File.dirname(__FILE__) + '/completions/food.yml'
puts "using config #{@config}"

include TestTools

#################################################

# test the tokenizer
testArrayContains("wow 'this is' handy".tokenize, "'this is'")
testArrayContains('wow "this is " handy'.tokenize, '"this is "')
testArrayContains('wow this\ is handy'.tokenize, 'this\ is')
testArrayContains("wow 'this is' handy".tokenize, "handy")
testArrayContains("wow 'this is' handy ".tokenize, "handy")
testArrayContains(" wow 'this is' handy ".tokenize, "wow")
testArrayContains("wow 'this is".tokenize, "'this is")
testArraysEqual 'food fruit banana '.split, 'food fruit banana '.tokenize

# expand space at end
expectedIs 'food -r', ['-r ']
# multiple matching options work
expectedIs 'food veg -m', ['-m ', '-maybe ']
# reference to another completion node
expectedContains 'food fruit banana ', 'banana '
# differentiate between choices where one name is a substring of the other 
expectedContains 'food fruit grape ', 'green '
expectedContains 'food fruit grapefruit ', 'yellow '
expectedContains 'food fruit grape', 'grape '
# ability to break into multiple parts and retrieve previous parts when needed
expectedIs 'food fruit --seedless', ['--seedless=false ', '--seedless=true ']
# ability to consume a partial match in a multi-part completer
expectedIs 'food fruit --seedless=f', ['--seedless=false ']
# dont crash if extra input isnt parsed
expectedIs 'food fruit grape green hare krishna', []

# test multilevel matches with repeated string
expectedIs 'food booze:', ['booze:booze ']
expectedIs 'food booze:b', ['booze:booze ']



# should try to match a known color
expectedIs 'food --color r', ['red ']
# but should still accept an unknown color too
expectedContains 'food --color violet ', 'avocado '
# and should not show the regex choice
expectedLength 'food --color ', 3 
# Regex choice still should not show even if its part of a multilevel choice 
expectedIs 'food dairy:cow=', []

# space should still be respected at the end of a regex
#expectedContains 'food --color violet', 'violet '

# direct shell exec completer
expectedIs 'food -f data/wo', ['data/wow ']


# file completer drills into a dir
expectedIs 'food -r data/wow', ['data/wow/']
# file completer can terminate anywhere on the path
expectedContains 'food -r wow ', 'fruit '
# file completer works with several matches sharing a common prefix (in which case it must return the full match, not the abbreviated, due to a bug in bash)
expectedIs 'food -r data/wow/d', ['data/wow/dang/', 'data/wow/duh/']
# file completer drills into a dir showing abbreviated matches when possible
expectedIs 'food -r data/wow/', ['dang','duh','huh']
# file completer returns full match when only one match found
expectedIs 'food -r data/wow/h', ['data/wow/huh/']
# file completer matches file
expectedIs 'food -r data/wow/huh/ho', ['data/wow/huh/ho ']
# file completer handles spaces in file name
expectedIs 'food -r data/spac', ['data/space\ lab/']
expectedIs 'food -r data/space\ lab/', ['data/space\ lab/orbit ']
expectedIs 'food -r data/space\ lab/o', ['data/space\ lab/orbit ']

puts "SUCCESS! All Tests PASSED"
