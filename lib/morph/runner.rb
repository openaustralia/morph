module Morph
  class Runner
    # options: repo_path, container_name, data_path, env_variables
    def self.compile_and_run(options)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      Dir.mktmpdir("morph") do |defaults|
        add_config_defaults_to_directory(options[:repo_path], defaults)
        remove_hidden_directories(defaults)

        Morph::DockerRunner.compile_and_run(options.merge(repo_path: defaults)) do |on|
          on.log { |s,c| wrapper.call(:log, s, c)}
          on.ip_address {|ip| wrapper.call(:ip_address, ip)}
        end
      end
    end

    def self.add_config_defaults_to_directory(source, dest)
      Morph::DockerUtils.copy_directory_contents(source, dest)
      # We don't need to check that the language is recognised because
      # the compiler is never called if the language isn't valid
      language = Morph::Language.language(dest)

      language.default_files_to_insert.each do |files|
        if files.all?{|file| !File.exists?(File.join(dest, file))}
          files.each do |file|
            FileUtils.cp(language.default_config_file_path(file), File.join(dest, file))
          end
        end
      end

      # Special behaviour for Procfile. We don't allow the user to override this
      FileUtils.cp(language.default_config_file_path("Procfile"), File.join(dest, "Procfile"))
    end

    # Remove directories starting with "."
    # TODO Make it just remove the .git directory in the root and not other hidden directories
    # which people might find useful
    def self.remove_hidden_directories(directory)
      Find.find(directory) do |path|
        FileUtils.rm_rf(path) if FileTest.directory?(path) && File.basename(path)[0] == ?.
      end
    end
  end
end
