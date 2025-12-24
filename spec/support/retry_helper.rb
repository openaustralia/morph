# typed: false
# frozen_string_literal: true

module RetryHelper
  # Helper method for retrying expectations that may fail intermittently (default timeout 15 seconds)
  # Usage:
  #   expect_eventually(timeout: 30) do |_duration|
  #     expect(Morph::DockerUtils.running_containers.count).to eq(running_count + 1)
  #   end
  def expect_eventually(timeout: 15, &block)
    start = Time.now.utc
    delay = 0.1

    loop do
      dur = Time.now.utc - start
      begin
        return block.call(dur)
      rescue RSpec::Expectations::ExpectationNotMetError => e
        raise e unless dur < timeout

        sleep delay
        delay = [delay + 0.1, 0.5].min
      end
    end
  end
end
