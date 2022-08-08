# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `coffee-script` gem.
# Please instead update this file by running `bin/tapioca gem coffee-script`.

# source://coffee-script-2.4.1/lib/coffee_script.rb:4
module CoffeeScript
  class << self
    # Compile a script (String or IO) to JavaScript.
    #
    # source://coffee-script-2.4.1/lib/coffee_script.rb:66
    def compile(script, options = T.unsafe(nil)); end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:55
    def engine; end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:58
    def engine=(engine); end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:61
    def version; end
  end
end

# source://coffee-script-2.4.1/lib/coffee_script.rb:7
CoffeeScript::CompilationError = ExecJS::ProgramError

# source://coffee-script-2.4.1/lib/coffee_script.rb:6
CoffeeScript::EngineError = ExecJS::RuntimeError

# source://coffee-script-2.4.1/lib/coffee_script.rb:5
CoffeeScript::Error = ExecJS::Error

# source://coffee-script-2.4.1/lib/coffee_script.rb:9
module CoffeeScript::Source
  class << self
    # source://coffee-script-2.4.1/lib/coffee_script.rb:45
    def bare_option; end

    # source://coffee-script-source-1.12.2/lib/coffee_script/source.rb:3
    def bundled_path; end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:37
    def contents; end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:49
    def context; end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:10
    def path; end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:14
    def path=(path); end

    # source://coffee-script-2.4.1/lib/coffee_script.rb:41
    def version; end
  end
end

# source://coffee-script-2.4.1/lib/coffee_script.rb:19
CoffeeScript::Source::COMPILE_FUNCTION_SOURCE = T.let(T.unsafe(nil), String)