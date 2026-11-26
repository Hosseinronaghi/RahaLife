"""Write public OAuth registration IDs for a release. Never accepts app secrets."""
import json
import os
from pathlib import Path
import sys

platform = sys.argv[1]
if platform not in ('android', 'ios', 'macos', 'linux', 'windows', 'web'):
    raise SystemExit('Unsupported platform')
client = os.environ.get('RAHA_DROPBOX_CLIENT_ID', '').strip()
if platform == 'web':
    redirect = os.environ.get('RAHA_DROPBOX_WEB_REDIRECT_URI', '').strip()
elif platform in ('linux', 'windows'):
    redirect = 'http://127.0.0.1:43829/callback'
else:
    redirect = 'com.raha.life.oauth:/callback'
if not client or not redirect:
    client = redirect = ''  # Unconfigured builds keep direct sign-in disabled.
# Validate the native Windows/Linux loopback path first. Do not enable an
# untested registration/callback type on other platforms.
onedrive_client = (
    os.environ.get('RAHA_ONEDRIVE_CLIENT_ID', '').strip()
    if platform in ('linux', 'windows') else ''
)
google_drive_client = (
    os.environ.get('RAHA_GOOGLE_DRIVE_CLIENT_ID', '').strip()
    if platform in ('linux', 'windows') else ''
)
destination = Path('build') / f'oauth-{platform}.json'
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps({
    'RAHA_DROPBOX_CLIENT_ID': client,
    'RAHA_DROPBOX_REDIRECT_URI': redirect,
    'RAHA_ONEDRIVE_CLIENT_ID': onedrive_client,
    'RAHA_ONEDRIVE_REDIRECT_URI': 'http://127.0.0.1:43829/callback'
    if onedrive_client else '',
    'RAHA_GOOGLE_DRIVE_CLIENT_ID': google_drive_client,
    'RAHA_GOOGLE_DRIVE_REDIRECT_URI': 'http://127.0.0.1:43829/callback'
    if google_drive_client else '',
}), encoding='utf-8')
print(f'OAuth build configuration written for {platform}; no client secret is embedded.')
