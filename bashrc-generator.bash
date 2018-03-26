
# dont include colon as a wordbreak char (otherwise wreaks havoc on completions like mvn eclipse:eclipse)
# unfortunately this must be preset in the calling shell, meaning it could affect other completion programs which may rely on it
export COMP_WORDBREAKS="${COMP_WORDBREAKS//:}"

# the main inclusion here, finds all askbash completers and registers them with the shell
eval "$($ASKBASH_HOME/bashrc-generator.rb)"

# a handy utility for exploring bash's native completion behavior.  lets you type askdebug and then uses the contents of test/askdebug.sh as the tab completion 
if [ "$ASKBASH_DEBUG" != "" ] && [ "$ASKBASH_DEBUG" != "0" ]; then
    complete -C "$ASKBASH_HOME/test/askdebug.sh" -o nospace askdebug
fi
