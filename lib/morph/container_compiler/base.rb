module Morph
  module ContainerCompiler
    class Base
      def self.docker_container_name(run)
        "#{run.owner.to_param}_#{run.name}_#{run.id}"
      end

      def self.create(type)
        case type
        when :legacy
          Morph::ContainerCompiler::Legacy
        when :buildpacks
          Morph::ContainerCompiler::Buildpacks
        else
          raise "Invalid type #{type}"
        end
      end

      # If image is present locally use that. If it isn't then pull it from the hub
      # This makes initial setup easier
      def self.get_or_pull_image(name)
        wrapper = Multiblock.wrapper
        yield(wrapper)

        begin
          Docker::Image.get(name)
        rescue Docker::Error::NotFoundError
          Docker::Image.create('fromImage' => name) do |chunk|
            data = JSON.parse(chunk)
            wrapper.call(:log, :internalout, "#{data['status']} #{data['id']} #{data['progress']}\n")
          end
        end
      end
    end
  end
end
