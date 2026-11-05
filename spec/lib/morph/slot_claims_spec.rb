# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::SlotClaims do
  before { Sidekiq.redis(&:flushdb) }

  describe ".claim" do
    it "never hands out more slots than are free when many workers ask at once" do
      allow(Morph::Runner).to receive(:available_slots).and_return(3)

      results = Array.new(20) { |i| Thread.new { described_class.claim(i + 1, has_container: false) } }.map(&:value)

      expect(results.count(true)).to eq 3
    end

    it "counts pending claims against the free slots" do
      allow(Morph::Runner).to receive(:available_slots).and_return(1)

      expect(described_class.claim(1, has_container: false)).to be true
      expect(described_class.claim(2, has_container: false)).to be false
    end

    it "is idempotent for a run that already holds a claim" do
      allow(Morph::Runner).to receive(:available_slots).and_return(1)

      expect(described_class.claim(1, has_container: false)).to be true
      expect(described_class.claim(1, has_container: false)).to be true
    end

    it "lets a run through that already has its container, whatever the count" do
      allow(Morph::Runner).to receive(:available_slots).and_return(0)

      expect(described_class.claim(1, has_container: true)).to be true
    end

    it "does not count a run that already has its container against the free slots twice" do
      # The container is already reflected in available_slots, so one slot is free
      allow(Morph::Runner).to receive(:available_slots).and_return(1)
      described_class.claim(1, has_container: true)

      expect(described_class.claim(2, has_container: false)).to be true
    end

    it "refuses when the cap has been lowered below the running containers" do
      allow(Morph::Runner).to receive(:available_slots).and_return(-2)

      expect(described_class.claim(1, has_container: false)).to be false
    end

    it "refuses and records nothing if the lock was lost while asking Docker" do
      allow(Morph::Runner).to receive(:available_slots) do
        Sidekiq.redis { |r| r.set(described_class::LOCK_KEY, "another-workers-token") }
        1
      end

      expect(described_class.claim(1, has_container: false)).to be false
      expect(Sidekiq.redis { |r| r.zcard(described_class::KEY) }).to eq 0
    end

    it "ignores claims that have gone stale" do
      allow(Morph::Runner).to receive(:available_slots).and_return(1)
      Sidekiq.redis { |r| r.zadd(described_class::KEY, Time.now.to_f - 1, "99") }

      expect(described_class.claim(1, has_container: false)).to be true
    end
  end

  describe ".with_lock" do
    def lock_value
      Sidekiq.redis { |r| r.get(described_class::LOCK_KEY) }
    end

    it "holds the lock while the block runs" do
      described_class.with_lock { |redis| expect(redis.get(described_class::LOCK_KEY)).not_to be_nil }
    end

    it "releases the lock when the block finishes" do
      described_class.with_lock { nil }

      expect(lock_value).to be_nil
    end

    it "releases the lock when the block raises" do
      expect { described_class.with_lock { raise "boom" } }.to raise_error("boom")

      expect(lock_value).to be_nil
    end

    it "does not delete a lock that another worker acquired after ours expired" do
      described_class.with_lock do |redis|
        # Our lock's TTL runs out and a second worker takes the lock in the gap
        # right after the first command of our unlock
        # Sidekiq 7 wraps a redis-client connection, so hook that inner client
        client = redis.instance_variable_get(:@client)
        taken = false
        allow(client).to receive(:call).and_wrap_original do |original, *args, **kwargs, &block|
          result = original.call(*args, **kwargs, &block)
          unless taken
            taken = true
            original.call("SET", described_class::LOCK_KEY, "another-workers-token")
          end
          result
        end
      end

      expect(lock_value).to eq "another-workers-token"
    end
  end

  describe ".release" do
    it "frees the slot for another run" do
      allow(Morph::Runner).to receive(:available_slots).and_return(1)
      described_class.claim(1, has_container: false)

      described_class.release(1)

      expect(described_class.claim(2, has_container: false)).to be true
    end
  end
end
