"""Acquire official source only; reuse and verify the pinned backup. Stdlib only."""
import hashlib
import json
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META, RAW = ROOT / 'data/metadata', ROOT / 'data/raw'
TAG, NAME = 'wide-world-importers-v1.0', 'WideWorldImporters-Standard.bak'
EXPECTED = '066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada'

def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'WWI-Portfolio-Stage2'}), timeout=120) as response:
        return response.read()

def main():
    META.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)
    release_path = META / 'release.json'
    if not release_path.exists():
        release_path.write_bytes(fetch(f'https://api.github.com/repos/microsoft/sql-server-samples/releases/tags/{TAG}'))
    release = json.loads(release_path.read_text(encoding='utf-8-sig'))
    asset = next(x for x in release['assets'] if x['name']==NAME)
    backup = RAW / NAME
    if not backup.exists():
        backup.write_bytes(fetch(asset['browser_download_url']))
    with backup.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    if digest != EXPECTED or backup.stat().st_size != asset['size']:
        raise RuntimeError('Backup differs from pinned source; do not overwrite.')
    commit_file = META / 'source_commit.json'
    if not commit_file.exists():
        commit_file.write_bytes(fetch('https://api.github.com/repos/microsoft/sql-server-samples/commits/master'))
    commit = json.loads(commit_file.read_text())['sha']
    base = f'https://raw.githubusercontent.com/microsoft/sql-server-samples/{commit}/'
    files = {
      'microsoft-license.txt':'license.txt',
      'wwi-readme.md':'samples/databases/wide-world-importers/README.md',
      'InvoiceCustomerOrders.official.sql':'samples/databases/wide-world-importers/wwi-ssdt/wwi-ssdt/Website/Stored%20Procedures/InvoiceCustomerOrders.sql',
      'InvoiceLines.official.sql':'samples/databases/wide-world-importers/wwi-ssdt/wwi-ssdt/Sales/Tables/InvoiceLines.sql',
    }
    sources=[]
    for name, rel in files.items():
        target=META/name
        if not target.exists(): target.write_bytes(fetch(base+rel))
        sources.append({'file':str(target.relative_to(ROOT)),'url':base+rel,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    manifest={
      'dataset':'Wide World Importers OLTP Standard','publisher':'Microsoft','release':TAG,
      'release_url':release['html_url'],'release_published_at':release['published_at'],
      'asset_id':asset['id'],'asset_created_at':asset['created_at'],'asset_updated_at':asset['updated_at'],
      'download_url':asset['browser_download_url'],'filename':NAME,'format':'SQL Server compressed full database backup (.bak)',
      'size_bytes':backup.stat().st_size,'sha256':digest,
      'obtained_at_utc':datetime.fromtimestamp(backup.stat().st_mtime,timezone.utc).isoformat(),
      'obtained_at_basis':'Original download last-write timestamp; file unchanged.',
      'verified_at_utc':datetime.now(timezone.utc).isoformat(),
      'license':'MIT; retain Microsoft copyright and permission notice; review upstream geographic source notices.',
      'documentation_commit':commit,
      'documentation_note':'Current pinned reference; embedded modules in inventory.json identify logic shipped with the restored artifact.',
      'sources':sources}
    manifest_path = META/'source_manifest.json'
    if manifest_path.exists():
        historical = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
        if historical.get('sha256') != EXPECTED:
            raise RuntimeError('Historical manifest has a different source; review before acquisition.')
        # Keep the published evidence and its audited hash intact on a new machine.
        manifest_path = META/'source_manifest.local.json'
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(manifest,ensure_ascii=False,indent=2))

if __name__=='__main__': main()
