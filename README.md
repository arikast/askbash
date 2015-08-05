About
=====

Version: 0.6

Askbash makes it easy to define your own bash autocompletions (that thing that happens when you type a command and hit the tab key once or twice) using an intuitive yaml syntax.  It also comes with a number of autocompletions pre-installed, which you can find in the completions/ directory.  

This means when you type a program name which matches one of the completers, such as "mvn", that you can tab-complete arguments to the program on the command line based on the definitions found in the corresponding completion file (in this case mvn.yml).

How to install
==============

- First make sure Ruby 2.0+ is installed (tested against 2.0, probably also works with 1.9).

- Add this to your .bashrc, substituting the real path to your askbash installation:

```bash
   # export ASKBASH_DEBUG=1
   export ASKBASH_HOME=/your-actual-path/askbash
   source $ASKBASH_HOME/bashrc-generator.bash
```

- Restart or source your shell for it to take effect. 
  You will now have a variable called $ASKBASH_HOME defined, and any completions found in the following places will be active (first match found wins)

```bash
   ~/.askbash/completions/*yml
   $ASKBASH_HOME/completions/*.yml
```


How to use
==========

Your custom autocompletions are driven from a set of yaml files.  For example, suppose you have a fictitious command called "food".  You might create this completion in a file called food.yml:

```yaml
   'food ':
       'fruit ':
           'orange ': 
           'banana ': 
       'veg ':
           'broccoli ':
```

After adding this file in ~/.askbash/completions/ and restarting your shell, you would now have autocompletion of "food " according to the static hierarchy defined in food.yml.  You could now type "food f" and hit tab to complete the text to "food fruit ".  You could then hit tab twice to get your next set of options, which would be "orange " and "banana ".

Here we explicitly add spaces to our choices because we want a space to be added when these words complete, but you don't have to do this.  You could also have a "multi-part" completion by not putting a space at the end:

```yaml
   'food ':
       'fruit ':
           'orange ': 
           'banana ': 
           '--seedless': 
               '=true ':
               '=false ':
       'veg ':
           'broccoli ':
```

Here the --seedless does not end with a space because the intention is to continue with =true or =false without any spaces in between.

Sometimes our intent is to select many options, for example "food fruit orange --seedless=true banana".  In this case, we use yaml's "reference" syntax to loop back to another node like this:

```yaml
   'food ':
       'fruit ': &fruit
           'orange ': *fruit
           'banana ': *fruit
           '--seedless': 
               '=true ': *fruit
               '=false ': *fruit
       'veg ':
           'broccoli ':
```

This "reference" syntax consists of an arbitrarily named anchor (here it is &fruit) followed by one or more references to it (in this case *fruit). Note that all nodes end with colons, even leaf nodes, but references still occur after the colon. 

### Dynamic completers

Sometimes aspects of your completion hierarchy might be dynamic.  For instance, perhaps in addition to =true and =false we also want to allow an arbitrary value here.  In this case you'd use a Regex completer like this: 

```yaml
   'food ':
       'fruit ': &fruit
           'orange ': 
           'banana ': 
           '--seedless': 
               '=true ': *fruit
               '=false ': *fruit
               '<Regex>.+ ': *fruit
       'veg ':
           'broccoli ':
```

There are many dynamic completers to do all sorts of things such as fill in a filename or list a running proc or execute an arbitrary bash command.  Take a look at the $ASKBASH_HOME/lib/completers/ to see the available completers.  Any of these completers can be used in your yml configuration; to use one, just use it in your *.yml in the same way we've used the Regex above and drop the "Completer.rb" suffix when refering to it.  So to use FileCompleter.rb for instance, you would specify <File> in your *.yml config.  

You can also of course easily write your own completer; just place it in lib/completers and then use it like any other.


Writing your own dynamic completer
==================================

See lib/completers/*.rb for examples of writing your own dynamic completer.  You basically just need to extend a class and implement a few methods.
You will also likely find it useful to enable debugging output, which can be done by setting an environment variable in your .bashrc like this:

```bash
   export ASKBASH_DEBUG=1
```

Then after restarting the shell, you'll find copious debugging info logged to $ASKBASH_HOME/askbash.log


Some nit-picky syntax/naming rules which MUST be followed
==========================================================

- If your Ruby completion class is called Abc, then it must be defined in a class called AbcCompleter whose definition can be found in $ASKBASH_HOME/lib/completers/AbcCompleter.rb

- If the command you are autocompleting is called foobar, then:

    * You must define its completions in $ASKBASH_HOME/completions/foobar.yml or ~/.askbash/completion/foobar.yml

    * The top level node inside foobar.yml must be 'foobar '

- If you want spaces after your completions, then you need to quote them and include the space as part of the completion, eg: 
    '-r ':

- As seen above, all completions must end with a colon, with the exception of references which occur after the colon (but the colon must still be present!)


Examples
=========

See completions/*.yml as well as test/completions/*yml for examples


