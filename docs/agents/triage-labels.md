# Triage labels

The skills speak in terms of five canonical triage roles. This file maps those
roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role, for example "apply the AFK-ready triage label",
use the corresponding label string from this table.

All five already exist on `openaustralia/morph` with these exact names and
descriptions, so apply them rather than creating new ones. Check with
`gh label list --repo openaustralia/morph`.

The repo carries a much larger label set alongside these, covering area
(`Front end`, `Back end`, `API`, `search`, `buildpacks`, `admin interface`),
kind (`bug`, `enhancement`, `New feature`, `documentation`, `security`,
`devops`, `dependencies`) and workflow (`ready`, `in progress`, `backlog`,
`High priority`). Those are orthogonal to triage state, so leave them alone
when moving an issue through the triage state machine.

Edit the right-hand column if the vocabulary ever changes.
