# interactive editor: use vim from within irb
begin
  require 'interactive_editor'
rescue LoadError => err
  warn "Couldn't load interactive_editor: #{err}"
end

# print methods local to an object's class
class Object
  def local_methods
    (methods - Object.instance_methods).sort
  end
end

# print only the most "interesting" methods for an object
class Object
  def interesting_methods
    case self.class
    when Class
      self.public_methods.sort - Object.public_methods
    when Module
      self.public_methods.sort - Module.public_methods
    else
      self.public_methods.sort - Object.new.public_methods
    end
  end
end

# configure irb
IRB.conf[:PROMPT_MODE]  = :SIMPLE
IRB.conf[:AUTO_INDENT]  = true
IRB.conf[:USE_READLINE] = true

# history
IRB.conf[:EVAL_HISTORY] = 1000
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"

# copy a string to the clipboard
def pbcopy(string)
  `echo "#{string}" | pbcopy`
  string
end

def fl(file_name)
  file_name += '.rb' unless file_name =~ /\.rb/
  $recent = file_name
  load "#{file_name}"
end

def rl
  fl($recent)
end
