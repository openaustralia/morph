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
    end
  end
end
