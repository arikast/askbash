module UniversalUtils

def debugMode?
    ENV["ASKBASH_DEBUG"]
end

def log(msg)
  debug = debugMode?
  if debug
      logfile = 'askbash.log'
      if ! ENV['ASKBASH_HOME'].nil?
          logfile = "#{ENV['ASKBASH_HOME']}/#{logfile}"
      end
      open(logfile, 'a') { |f|
          if debug == "2"
              f.puts caller[2], msg
          elsif debug.to_i > 2
              f.puts caller, msg
          else
              f.puts msg
          end
      }
  end
end

def completerClassFromString(str)
    completerClassname = "#{str}"
    file = "#{File.dirname(__FILE__)}/completers/#{completerClassname}.rb" 
    #load class on demand.  ruby file must be named same as the ruby class + ".rb"
    if File.exist? file
        require_relative file
    else
        log "#{file} not found while instantiating #{completerClassname}"
    end
    classFromString completerClassname
end

def classFromString(str)
    str.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
    end
end

def runShellCommand(cmd)
  log "abt to exec #{cmd}"
  answer = `#{cmd}`.split
  log "got answer #{answer}"
  #TODO: handle error condition
  return answer
end

end
