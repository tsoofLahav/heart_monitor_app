"""Create a private APK signing key once; never overwrite an existing key."""
import os
from pathlib import Path
import secrets
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
properties = root / 'android/key.properties'
keystore = root / 'android/private-release.jks'
if properties.exists() or keystore.exists():
    raise SystemExit('Signing files already exist; keep them to preserve Android updates.')
keytool = shutil.which('keytool')
if not keytool:
    raise SystemExit('Install a JDK with keytool before running this script.')
os.umask(0o077)
password = secrets.token_urlsafe(36)
env = dict(os.environ, MONITOR_KEY_PASSWORD=password)
subprocess.run([
    keytool, '-genkeypair', '-noprompt', '-keystore', str(keystore),
    '-storetype', 'JKS', '-alias', 'monitor', '-keyalg', 'RSA', '-keysize', '3072',
    '-validity', '10000', '-dname', 'CN=Monitor Android',
    '-storepass:env', 'MONITOR_KEY_PASSWORD', '-keypass:env', 'MONITOR_KEY_PASSWORD',
], env=env, check=True)
properties.write_text(
    f'storeFile=private-release.jks\nstorePassword={password}\n'
    f'keyAlias=monitor\nkeyPassword={password}\n'
)
print('Created ignored android/key.properties and android/private-release.jks. Back up both securely.')
