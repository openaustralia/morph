# One Owner, many Forge identities, one nickname

Status: accepted

An Owner may hold one Forge identity per Forge, so a person or organisation
present on both GitHub and GitLab is a single Owner, and the Owner's `nickname`
stays the one slug behind every URL and API path (`/:nickname`,
`/:owner/:name`). The `(forge, uid)` pair is unique across all identities and
`nickname` is unique across all Owners. A GitLab login already taken by a
GitHub user gets a suffixed slug on morph.io while showing its real login.

Linking exists because OAF staff need to move scrapers from GitHub to GitLab
without the scraper's URL, data, runs or watchers changing hands. That is only
coherent if the Owner on both sides is the same record. The alternative, one
Owner per forge account, would have been simpler, but a migrated scraper would
then belong to a different Owner and every published data URL and README badge
for it would break.

Keeping `nickname` as the single slug is the same trade made in the other
direction: prefixing routes by forge (`/gitlab/alice/foo`) would be the tidier
long-term shape, but it too breaks every existing URL, and collisions between
a GitHub login and a GitLab login are rare enough that a suffix is an honest
answer.

## Considered options

- One Owner per forge account, no linking: rejected, because it makes the
  GitHub-to-GitLab migration a new scraper under a new Owner.
- Forge-prefixed routes for everything, with redirects from the old URLs:
  rejected, because morph.io's data URLs are embedded in other people's code
  and READMEs, and a redirect is not a promise the API clients honour.
- Merging two existing Owners when someone links accounts that were each
  already on morph.io: out of scope. Linking is refused in that case.

## Consequences

- Organizations link too. The OAF GitHub organisation and the OAF GitLab group
  are one Organization, so an Organization can hold a Forge identity for each.
  Linking a group needs someone who is already a member of the Organization on
  morph.io and holds Owner on the GitLab group, proven through the API with a
  freshly authorised GitLab token.
- Unlinking is refused for an Owner's last identity, and for any identity that
  a Scraper still depends on.
- Provider, uid and access token move off `owners` into a `forge_identities`
  table. Nothing may look an Owner up by `nickname` and assume it means a
  GitHub login.
