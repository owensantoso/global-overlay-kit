#!/usr/bin/env python3
"""Install this companion's files. Run through private-tailnet-delivery's deployment gate."""
import json
from pathlib import Path
import plistlib
import secrets
import shutil
import sys

source = Path(__file__).resolve().parents[1]
runtime = Path(sys.argv[1]).resolve()
public_url = sys.argv[2]
port = int(sys.argv[3])
runtime.mkdir(parents=True, exist_ok=True)
for name in ('dist', 'server'):
    shutil.copytree(source / name, runtime / name, dirs_exist_ok=True)
config_path = runtime / 'config.json'
if config_path.exists():
    config = json.loads(config_path.read_text())
else:
    config = {'nativeSecret': secrets.token_hex(32)}
config.update(port=port, publicURL=public_url, staticRoot=str(runtime / 'dist'))
config_path.write_text(json.dumps(config))
config_path.chmod(0o600)
native_dir = Path.home() / 'Library/Application Support/Desktop Phone World'
native_dir.mkdir(parents=True, exist_ok=True)
native_config = native_dir / 'config.json'
native_config.write_text(json.dumps({'nativeSecret': config['nativeSecret'], 'port': port}))
native_config.chmod(0o600)
plist_path = Path.home() / 'Library/LaunchAgents/local.owen.desktop-phone-world.plist'
plist_path.parent.mkdir(parents=True, exist_ok=True)
plist = {
    'Label': 'local.owen.desktop-phone-world',
    'ProgramArguments': [shutil.which('node'), str(runtime / 'server/server.mjs'), str(config_path)],
    'WorkingDirectory': str(runtime), 'RunAtLoad': True, 'KeepAlive': True,
    'ThrottleInterval': 10, 'StandardOutPath': str(runtime / 'service.log'),
    'StandardErrorPath': str(runtime / 'service-error.log'),
    'EnvironmentVariables': {'TMPDIR': str(runtime / 'tmp')},
}
(runtime / 'tmp').mkdir(exist_ok=True)
plist_path.write_bytes(plistlib.dumps(plist))
print('Installed Desktop Phone World companion files and LaunchAgent definition.')
