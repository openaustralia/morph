# Ruby 3.4 only on the new server

Status: accepted

The upgrade plan originally kept Ruby 3.0.7 through cutover so that one
application state could run on both the old and new servers. That premise
hits a wall: Ruby 3.0 and older do not build against OpenSSL 3, which is
all Ubuntu 24.04 ships. The new server therefore runs Ruby 3.4 only, the
Ruby 3.0.7 to 3.4 hop happens before cutover and is validated on the
rehearsal server, and Rails 7.1 (which supports Ruby 3.0 through 3.4) is
the bridge codebase across the migration.

The premise was also stronger than needed: rollback during the cutover
window is a DNS flip back to the untouched old server, not a redeploy, so
no moment requires one deployable state on both machines.

## Considered options

- Vendor OpenSSL 1.1.1 into rvm on the new server so Ruby 3.0.7 runs
  there: rejected, because it puts an end-of-life crypto library (and an
  end-of-life Ruby) on the box this migration exists to make supportable.

## Consequences

- Landing the Ruby 3.4 change on `main` ends deployability to the old
  server, whose ceiling is Ruby 3.0.7. It merges only after the rehearsal
  server has validated it, shortly before cutover; until then it lives on
  a branch deployed to the rehearsal server only.
- Phase 6 of the upgrade plan starts at the Rails 7.2 hop with Ruby
  already done.
