# Stay on Linode for the server migration

Status: accepted

Decided with OAF ops, 20 August 2026. The rest of the OAF fleet runs on AWS
and the infrastructure repository's tooling (inventory, CloudWatch, SSM,
backups) is AWS-shaped, so EC2 was the obvious default. The new morph server
stays on Linode anyway, because morph's workload is scraping: outbound IP
reputation matters, AWS address ranges are aggressively blocked by anti-bot
services, and moving could silently degrade hundreds of scrapers in ways no
rehearsal would reveal. Continuity and cheap egress for the bulk data move
are secondary benefits.

## Consequences

- The managed-database question (RDS, #1375) is moot while hosting stays
  Linode.
- The AWS-shaped conveniences in the infrastructure repository are forgone
  for morph; revisit this decision if those ever outweigh the
  IP-reputation risk, with a plan for measuring scraper success rates
  before and after any move.
