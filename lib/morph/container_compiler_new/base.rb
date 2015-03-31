module Morph
  module ContainerCompilerNew
    class Base
      def self.docker_container_name(run)
        Morph::ContainerCompiler.docker_container_name(run)
      end
    end
  end
end
