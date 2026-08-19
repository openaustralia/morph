# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues on
[`openaustralia/morph`](https://github.com/openaustralia/morph). Use the `gh`
CLI for all operations. Run it inside the clone and it infers the repo from
`git remote -v`.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a
  heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments
  by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`
  with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply or remove labels**: `gh issue edit <number> --add-label "..."` or
  `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

## Repo specifics

- The issue and pull request templates are inherited from
  [`openaustralia/.github`](https://github.com/openaustralia/.github), not held
  locally, so `gh issue create` will not offer a template to fill in. Follow
  the org template's structure by hand.
- Assign every pull request you open to yourself
  (`gh pr create --assignee @me`), per the org `CONTRIBUTING.md`.
- Disclose AI involvement as that guide asks: an
  `Assisted-by: <agent-name>:<model-id>` trailer on each commit and a note in
  the pull request description.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external
PRs as feature requests. `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using
the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments`, and `gh pr diff <number>`
  for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`
  then keep only `authorAssociation` of `CONTRIBUTOR`,
  `FIRST_TIME_CONTRIBUTOR` or `NONE`, dropping `OWNER`, `MEMBER` and
  `COLLABORATOR`.
- **Comment, label, close**: `gh pr comment`, `gh pr edit --add-label` or
  `--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be
either. Resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as
tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes,
  Decisions-so-far and Fog body. `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api`
  on the sub-issues endpoint). Where sub-issues are not enabled, add the child
  to a task list in the map body and put `Part of #<map>` at the top of the
  child body. Labels: `wayfinder:<type>`, one of `research`, `prototype`,
  `grilling` or `task`. Once claimed, the ticket is assigned to the driving
  dev.
- **Blocking**: GitHub's **native issue dependencies**, which is the canonical,
  UI-visible representation. Add an edge with
  `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`,
  where `<blocker-db-id>` is the blocker's numeric **database id**
  (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, not the `#number` or the
  `node_id`). GitHub reports `issue_dependencies_summary.blocked_by`, counting
  open blockers only, which is the live gate. Where dependencies are not
  available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the
  child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`,
  scoped to the map's sub-issues or task list), drop any with an open blocker
  (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the
  `Blocked by` line) or an assignee. First in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me`, the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then
  `gh issue close <n>`, then append a context pointer (gist plus link) to the
  map's Decisions-so-far.
