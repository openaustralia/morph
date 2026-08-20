# Upgrade morph in place rather than replace it

Status: accepted

Almost every layer of morph.io is past end of life, and the alternative of
replacing it with a simpler AWS-native system was considered and rejected
(openaustralia/oaf-internal#308). morph.io is a working product with active
users, thousands of scrapers and years of accumulated data; a rewrite risks
all of that to solve a versions problem. We upgrade the existing application
in place, in small verified hops, per the plan in
[`doc/UPGRADE_PATH.md`](../../doc/UPGRADE_PATH.md).
