#!/usr/bin/env python3
import os
import sys
import json
from pathlib import Path
from dotenv import dotenv_values

# Load .env from project root (two levels up from inventory dir)
env_path = Path(__file__).parent.parent.parent / '.env'

# Read values directly from file only
env_values = dotenv_values(env_path)

staging_hostname = env_values.get('STAGING_HOSTNAME')
staging_deploy_to = env_values.get('STAGING_DEPLOY_TO')

if '--debug' in sys.argv:
    print(f"env_path: {env_path}", file=sys.stderr)
    print(f"env_path exists: {env_path.exists()}", file=sys.stderr)
    print(f"STAGING_HOSTNAME: {staging_hostname}", file=sys.stderr)
    print(f"STAGING_DEPLOY_TO: {staging_deploy_to}", file=sys.stderr)

if not staging_hostname:
    print("ERROR: STAGING_HOSTNAME not set in .env file", file=sys.stderr)
    exit(1)

# Build host vars - use IP for SSH connection if provided
hostvars = {}
if staging_deploy_to:
    hostvars["ansible_ssh_host"] = staging_deploy_to

# Add staging-specific variables
hostvars["server_name"] = staging_hostname
hostvars["morph_url"] = f"https://{staging_hostname}"

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
