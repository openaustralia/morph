module Morph
  class ContainerCompiler
    def self.compile_and_run_original(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      Morph::ContainerCompilerNew::Base.create(:legacy).compile_and_run(run) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
        on.ip_address {|ip| wrapper.call(:ip_address, ip)}
      end
    end

    def self.compile_and_run_with_buildpacks(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      Morph::ContainerCompilerNew::Base.create(:buildpacks).compile_and_run(run) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
        on.ip_address {|ip| wrapper.call(:ip_address, ip)}
      end
    end
  end
end
