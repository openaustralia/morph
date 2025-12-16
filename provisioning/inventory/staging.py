#!/usr/bin/env python3
import os
import sys
import json
from pathlib import Path
from dotenv import dotenv_values

# Load .env from project root (two levels up from inventory dir)
project_root = Path(__file__).parent.parent.parent
env_staging_path = project_root / '.env.staging'
env_path = project_root / '.env'

# Read from .env.staging first, then .env
env_values = dotenv_values(env_path)
if env_staging_path.exists():
    env_values.update(dotenv_values(env_staging_path))

variables = [
    ('STAGING_HOSTNAME', None),
    ('STAGING_DEPLOY_TO', None),
    ('GITHUB_APP_ID', 'TODO-SET-IN-.env'),
    ('GITHUB_APP_NAME', 'TODO-SET-IN-.env'),
    ('GITHUB_APP_CLIENT_ID', 'TODO-SET-IN-.env'),
    ('GITHUB_APP_CLIENT_SECRET', 'TODO-SET-IN-.env'),
    ('CUTTLEFISH_SERVER', 'plannies-mate.thesite.info'),
    ('CUTTLEFISH_PORT', '2525'),
    ('CUTTLEFISH_USERNAME', None),
    ('CUTTLEFISH_PASSWORD', None),
]

hostvars = {}
for env_name, default in variables:
    if env_values.get(env_name, default):
      hostvars[env_name.lower()] = env_values.get(env_name, default)

if '--debug' in sys.argv:
    print(f"env_path: {env_path}", file=sys.stderr)
    print(f"env_path exists: {env_path.exists()}", file=sys.stderr)
    for env_name, _ in variables:
        print(f"{env_name}: {hostvars[env_name.lower()]}  \t[ansible {env_name.lower()} var]", file=sys.stderr)

staging_hostname = hostvars['staging_hostname']
if not staging_hostname:
    print("ERROR: STAGING_HOSTNAME not set in .env file", file=sys.stderr)
    exit(1)
hostvars["server_name"] = staging_hostname
hostvars["morph_url"] = f"https://{staging_hostname}"


# Special handling
if hostvars['staging_deploy_to']:
    hostvars["ansible_ssh_host"] = hostvars['staging_deploy_to']

inventory = {
    "_meta": {
        "hostvars": {
            staging_hostname: hostvars
        }
    },
    "all": {
        "children": ["staging"]
    },
    "staging": {
        "hosts": [staging_hostname]
    }
}

print(json.dumps(inventory))
