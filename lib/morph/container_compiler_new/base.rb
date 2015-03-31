module Morph
  module ContainerCompilerNew
    class Base
      def self.docker_container_name(run)
        "#{run.owner.to_param}_#{run.name}_#{run.id}"
      end

      def self.create(type)
        case type
        when :legacy
          Morph::ContainerCompilerNew::Legacy
        when :buildpacks
          Morph::ContainerCompilerNew::Buildpacks
        else
          raise "Invalid type #{type}"
        end
      end
    end
  end
end
