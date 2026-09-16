# Layered repository credentials for GitLab

Status: accepted

morph.io reaches a GitLab repository with the most durable credential the
Owner's GitLab plan and the connecting person's role allow, falling through
to weaker ones, rather than requiring one particular kind. In preference
order: a group access token (a bot member of the group, so it survives people
leaving and covers the API and `git clone` alike); a deploy token for cloning
plus a Collaborator's OAuth token for the API; a Collaborator's OAuth token on
its own. Which tier is active is found by trying to create each in turn, not by
reading the group's plan, and is shown on the Organization's page along with
what would unlock the next tier.

The GitHub side of morph.io leans on a GitHub App installation, which acts as
the organisation, needs nobody's personal token, and is free. GitLab has no
equivalent that is available to everyone: its resource access tokens (group and
project) are the same shape but are Premium and Ultimate only on gitlab.com,
and its free durable option, the deploy token, can clone but cannot call the
API for members or visibility. OAuth tokens are always available but belong to
a person, expire after two hours, and stop working when that person leaves.

OAF's own gitlab.com group is on Ultimate through GitLab's open source
programme, so the group access token tier is real for the migration this was
built for. Almost every other GitLab user of morph.io will be on Free, so the
lower tiers are the normal path, not a fallback for edge cases.

## Considered options

- Require a group or project access token: rejected, because it would shut out
  every Free-tier user, which is most of them.
- OAuth tokens only, matching how morph.io worked before the GitHub App:
  rejected, because a scraper would stop syncing the day the person who added
  it left the group, which is the failure the GitHub App was introduced to end.
- A morph.io bot account users add as a member: rejected, because it recreates
  the "install the App" step people already find confusing, on a forge that
  offers better options to those who can use them.

## Consequences

- When the clone credential works but no API credential does, a Run goes ahead
  on last-known permissions and the Scraper is flagged as needing attention,
  rather than failing. A durable clone token would be pointless otherwise.
- Access tokens on GitLab expire, so morph.io holds refresh tokens and rotates
  them under a database row lock, because GitLab invalidates the old refresh
  token on use and two workers refreshing at once would log each other out.
- Public GitLab repositories are held to the same rules as private ones, as
  they are on GitHub: an anonymous clone with no API access is refused rather
  than silently run with stale permissions.
- Trying-then-falling-through is what makes a self-hosted GitLab instance
  possible later, where plan names mean nothing.
