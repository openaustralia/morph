# typed: strict
# frozen_string_literal: true

module Morph
  # The concurrency cap is enforced by counting Docker containers, but a run
  # only gets its container after it has synchronised its repository from
  # GitHub, which takes seconds. Without this, every worker thread that looks
  # in that gap sees the same free slot. A claim holds a slot from the moment a
  # run is allowed to start until its container exists, and the check and the
  # claim happen under a short Redis lock so that they are one step.
  module SlotClaims
    extend T::Sig

    KEY = "morph:slot_claims"
    LOCK_KEY = "morph:slot_claims:lock"
    # A claim from a worker that died before its container started goes stale.
    # A build that takes longer than this loses its claim while still running,
    # so the cap can be briefly exceeded. Builds are expected to be shorter.
    CLAIM_TTL = T.let(15 * 60, Integer)
    LOCK_TTL_MS = T.let(10_000, Integer)
    LOCK_WAIT = T.let(15, Integer)
    # Deletes the lock only if it still holds our token. Done as one script so
    # that the lock cannot expire and be re-acquired by another worker between
    # the check and the delete. EVAL is available from Redis 2.6.
    UNLOCK_SCRIPT = T.let(<<~LUA, String)
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      end
      return 0
    LUA
    # Records the claim only if we still hold the lock. available_slots asks
    # Docker, which can take longer than LOCK_TTL_MS, and if the lock expired in
    # the meantime another worker may have read the same free slot.
    CLAIM_SCRIPT = T.let(<<~LUA, String)
      if redis.call("get", KEYS[1]) == ARGV[1] then
        redis.call("zadd", KEYS[2], ARGV[2], ARGV[3])
        return 1
      end
      return 0
    LUA

    # Claims a slot for the run if one is free. Returns false if none is.
    sig { params(run_id: Integer, has_container: T::Boolean).returns(T::Boolean) }
    def self.claim(run_id, has_container:)
      with_lock do |redis, token|
        now = Time.now.to_f
        redis.zremrangebyscore(KEY, "-inf", now)
        pending = redis.zrange(KEY, 0, -1).reject { |id| id == run_id.to_s }.count
        # A run that already has its container has already taken its slot, which
        # available_slots counts, so holding a claim as well would count it twice
        next true if has_container

        next false unless (Morph::Runner.available_slots - pending).positive?

        # Losing the lock means a refusal here, so the run tries again shortly
        redis.eval(CLAIM_SCRIPT, keys: [LOCK_KEY, KEY], argv: [token, now + CLAIM_TTL, run_id.to_s]) == 1
      end
    end

    sig { params(run_id: Integer).void }
    def self.release(run_id)
      Sidekiq.redis { |redis| redis.zrem(KEY, run_id.to_s) }
    end

    sig { type_parameters(:U).params(block: T.proc.params(redis: T.untyped, token: String).returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
    def self.with_lock(&block)
      Sidekiq.redis do |redis|
        token = SecureRandom.hex(8)
        deadline = Time.current + LOCK_WAIT
        until redis.set(LOCK_KEY, token, nx: true, px: LOCK_TTL_MS)
          raise "Timed out waiting for the slot claim lock" if Time.current > deadline

          sleep 0.05
        end
        begin
          block.call(redis, token)
        ensure
          redis.eval(UNLOCK_SCRIPT, keys: [LOCK_KEY], argv: [token])
        end
      end
    end
  end
end
