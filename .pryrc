Pry.editor = 'vim'

if defined?(PryByebug)
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
  Pry.commands.alias_command 'c', 'continue'
end

if defined?(PryStackExplorer)
  Pry.commands.alias_command 'bt', 'show-stack'
end
