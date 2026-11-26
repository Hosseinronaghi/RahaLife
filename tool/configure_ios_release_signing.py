"""Select the single supplied Ad Hoc profile for the existing Runner identifier."""

import datetime
import os
from pathlib import Path
import plistlib
import re
import sys

raw_profile, export = map(Path, sys.argv[1:])
profile = plistlib.loads(raw_profile.read_bytes())
team = os.environ['RAHA_APPLE_TEAM_ID']
details = profile['Entitlements']
safe_profile_name = re.compile(r"^[A-Za-z0-9 _().-]{1,150}$")
name = profile['Name']
uuid = profile['UUID']
if (not re.fullmatch(r'[A-Fa-f0-9-]{36}', uuid) or
    not safe_profile_name.fullmatch(name) or team not in profile['TeamIdentifier'] or
    profile['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None) or
    not profile.get('ProvisionedDevices') or details.get('get-task-allow') is not False):
    raise SystemExit('Use an unexpired Ad Hoc distribution profile for this team.')
prefix, _, bundle_id = details['application-identifier'].partition('.')
if (prefix not in profile['ApplicationIdentifierPrefix'] or
    not re.fullmatch(r'[A-Za-z0-9.-]+', bundle_id)):
    raise SystemExit('The supplied profile must have an explicit bundle identifier.')
container = os.environ.get('RAHA_ICLOUD_CONTAINER', '')
if container and (container not in details.get('com.apple.developer.icloud-container-identifiers', []) or
                  'CloudDocuments' not in details.get('com.apple.developer.icloud-services', [])):
    raise SystemExit('The supplied profile does not authorize this iCloud Documents container.')

project = Path('ios/Runner.xcodeproj/project.pbxproj')
data = project.read_text(encoding='utf-8')
release_config_count = 0

def rewrite(match):
    global release_config_count
    body = match.group(1)
    runner = re.search(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', body)
    if not runner or runner.group(1).endswith('.RunnerTests'):
        return match.group(0)
    if runner.group(1).strip('"') != bundle_id:
        raise SystemExit('Provisioning profile does not match the existing app ID.')
    body = re.sub(r'(?m)^\s*(CODE_SIGN_STYLE|CODE_SIGN_IDENTITY|DEVELOPMENT_TEAM|PROVISIONING_PROFILE_SPECIFIER) = [^;]+;\n', '\n', body)
    release_config_count += 1
    return ('buildSettings = {' + body +
            f'\n\t\t\t\tCODE_SIGN_STYLE = Manual;'
            f'\n\t\t\t\tCODE_SIGN_IDENTITY = "Apple Distribution";'
            f'\n\t\t\t\tDEVELOPMENT_TEAM = {team};'
            f'\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{name}";'
            '\n\t\t\t};')

data = re.sub(r'buildSettings = \{([^{}]*)\};', rewrite, data)
if release_config_count < 1:
    raise SystemExit('Could not configure signed Runner target.')
project.write_text(data, encoding='utf-8')
options = {
    'method': 'release-testing',
    'signingStyle': 'manual',
    'teamID': team,
    'signingCertificate': 'Apple Distribution',
    'provisioningProfiles': {bundle_id: name},
}
if container:
    options['iCloudContainerEnvironment'] = 'Production'
export.write_bytes(plistlib.dumps(options))
print(uuid)
