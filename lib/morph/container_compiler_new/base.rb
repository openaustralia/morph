module Morph
  module ContainerCompilerNew
    class Base
      def self.docker_container_name(run)
        "#{run.owner.to_param}_#{run.name}_#{run.id}"
      end
    end
  end
end
