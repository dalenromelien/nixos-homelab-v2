# Immich Migration: NixOS → NixOS

This guide migrates Immich from the current NixOS source machine to the target home-server NixOS machine configured in [the repository's home-server host](../hosts/home-server/default.nix).

The source machine is the machine that currently owns the Immich data. The target machine is the new home-server NixOS machine whose RAID1 storage is mounted at `/data`.

> **Important:** Immich media must end up at `/data/immich` on the target. The target's SSD-only `/DATA/.media/SSD-Storage` path is intentionally not used.

## Storage layout

The target storage layout is:

```text
/data                         # RAID1 mount point from disk-config.nix
└── immich                    # Immich media root
    ├── upload
    ├── library
    ├── thumbs
    └── ...
```

The target's `services.immich.mediaLocation` is already configured as `/data/immich` in [modules/services/immich.nix](../modules/services/immich.nix). The migration must therefore copy files directly into that path and must not place them under the SSD storage mount.

## Prerequisites

- The source and target are both NixOS machines with the same or compatible Immich versions.
- The target's `services.immich.mediaLocation` is `/data/immich`.
- The target `/data` filesystem is the RAID1 filesystem, not the SSD storage mount.
- SSH access is available to both machines as `root`. Change the variables below if your SSH setup uses another account.
- The source and target have enough free disk space for the media copy plus the database dump.
- The source's Immich database is the database that should be migrated, normally `immich`.

Confirm the target filesystem before starting:

```bash
# Run on the target
findmnt -T /data
findmnt -T /data/immich 2>/dev/null || true
```

The output for `/data` must show the RAID1-backed filesystem. Do not proceed if `/data` is the SSD storage mount or if `/data` is not mounted.

## 1. Confirm versions and paths

Run these commands on their respective machines.

### Source machine

```bash
sudo systemctl is-active immich-server
sudo systemctl is-active immich-machine-learning
sudo systemctl is-active postgresql.service

sudo systemctl cat immich-server | grep -oE 'immich-[0-9]+\.[0-9]+\.[0-9]+' | head -1

sudo test -d /data/immich
sudo find /data/immich -mindepth 1 -maxdepth 1 -print | head
```

### Target machine

```bash
sudo systemctl is-active immich-server
sudo systemctl is-active immich-machine-learning
sudo systemctl is-active postgresql.service

sudo systemctl cat immich-server | grep -oE 'immich-[0-9]+\.[0-9]+\.[0-9]+' | head -1

sudo test -d /data
findmnt -T /data
```

The target Immich version should be the same version as the source or newer. Do not restore into an older Immich version.

If the source and target version differ, update the target's NixOS/Immich package first and verify the target version again. The source and target should ideally use the same NixOS package version and Immich version.

## 2. Prepare the target

The target should be configured with the existing module settings:

```nix
services.immich = {
  enable = true;
  host = "127.0.0.1";
  port = 2283;
  mediaLocation = "/data/immich";
};
```

Apply the target configuration before the migration:

```bash
# Run on the target
sudo nixos-rebuild switch --flake /path/to/nixos-homelab-v2#home-server
sudo systemctl stop immich-server immich-machine-learning
sudo systemctl start postgresql.service
```

If the target already has an Immich media directory, move it out of the way before copying the source data:

```bash
# Run on the target
if [ -e /data/immich ]; then
  sudo mv /data/immich /data/immich-pre-migration
fi

sudo install -d -o immich -g immich -m 0750 /data/immich-import
```

The pre-migration directory is retained as a rollback copy. It must remain on the same RAID1 filesystem as `/data/immich`.

## 3. Stop the source application and create a database dump

The source application must be stopped before the media and database are copied. PostgreSQL remains running while the database dump is created.

Run these commands on the source machine:

```bash
sudo systemctl stop immich-server immich-machine-learning
sudo systemctl is-active postgresql.service

sudo -u postgres psql -d immich -c '\dx'
sudo -u postgres pg_dump \
  --no-owner \
  --no-privileges \
  --format=plain \
  --dbname=immich \
  | gzip -9 > /data/immich-migration-dump.sql.gz

gzip -t /data/immich-migration-dump.sql.gz
ls -lh /data/immich-migration-dump.sql.gz
```

The `\dx` command should show the extensions required by the installed Immich version. If the target does not provide an extension used by the dump, update the target's NixOS package or the target's PostgreSQL configuration before continuing. Do not remove or rewrite database schema objects merely to make the restore succeed.

Keep the source application stopped while the media is copied and while the database is restored.

## 4. Copy the media to the target RAID1 filesystem

The source media path is deliberately not the target path. This makes the copy independent of the source machine's mount layout.

Set the host variables on the source machine:

```bash
export TARGET_HOST=root@target-host
export TARGET_STAGING=/data/immich-import
```

Copy the complete media tree, including hidden files such as `.immich` markers:

```bash
sudo rsync -aHAX \
  --numeric-ids \
  --no-owner \
  --no-group \
  --delete \
  --info=progress2 \
  /data/immich/ \
  "${TARGET_HOST}:${TARGET_STAGING}/"
```

The trailing slash copies the contents of `/data/immich`, including hidden files. The target staging directory is under `/data`, so the entire copy stays on the RAID1 volume.

The source and target media should now match. Run a checksum verification before replacing the target's final media directory:

```bash
sudo rsync -aHAX \
  --numeric-ids \
  --no-owner \
  --no-group \
  --checksum \
  --delete \
  --dry-run \
  --itemize-changes \
  /data/immich/ \
  "${TARGET_HOST}:${TARGET_STAGING}/"
```

No output means the source and staged media are identical. If output is shown, stop and resolve the differences before continuing.

## 5. Transfer the database dump

Copy the dump to the target, outside the Immich media directory:

```bash
# Run on the source
sudo rsync -aHAX \
  --numeric-ids \
  /data/immich-migration-dump.sql.gz \
  "${TARGET_HOST}:/root/immich-migration-dump.sql.gz"
```

Verify the dump on the target:

```bash
# Run on the target
sudo gzip -t /root/immich-migration-dump.sql.gz
sudo ls -lh /root/immich-migration-dump.sql.gz
```

## 6. Install the copied media at `/data/immich`

The target's final media directory must be the RAID1-mounted `/data/immich` path. Replace the pre-existing target directory only after the staged copy has passed verification.

Run on the target:

```bash
sudo test -d /data/immich-import
sudo test -d /data

if [ -e /data/immich ]; then
  sudo mv /data/immich /data/immich-pre-migration
fi

sudo mv /data/immich-import /data/immich
sudo chown -R immich:immich /data/immich
sudo find /data/immich -type d -exec chmod 0750 {} +
sudo find /data/immich -type f -exec chmod 0640 {} +

findmnt -T /data/immich
sudo ls -la /data/immich
sudo ls -la /data/immich/upload | head
```

The resulting tree must be:

```text
/data/immich
```

Not:

```text
/DATA/.media/SSD-Storage/immich
```

The SSD storage path is not part of this migration.

## 7. Restore the database into the target

The target database must be fresh. If the target already has an Immich database, make a backup first and then drop it.

Run the following on the target. The temporary superuser permission is required because the dump may create vector extensions and database objects owned by the `immich` role.

```bash
sudo -u postgres psql -c 'DROP DATABASE IF EXISTS immich;'
sudo -u postgres psql -c 'CREATE DATABASE immich OWNER immich;'
sudo -u postgres psql -c 'ALTER USER immich WITH SUPERUSER;'

zcat /root/immich-migration-dump.sql.gz \
  | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
  | sudo -u immich psql -d immich --single-transaction --set ON_ERROR_STOP=on

sudo -u postgres psql -c 'ALTER USER immich WITH NOSUPERUSER;'
```

If the restore fails, stop before starting Immich. The database transaction should be rolled back, and the target can be retried after resolving the error.

## 8. Start Immich and verify the migration

Start the application on the target:

```bash
sudo systemctl start immich-server immich-machine-learning
sudo systemctl status immich-server immich-machine-learning
sudo journalctl -u immich-server -n 100 --no-pager
```

Verify the media path and permissions:

```bash
sudo test -d /data/immich/upload
sudo test -d /data/immich/library
sudo test -d /data/immich/thumbs
sudo test -f /data/immich/upload/.immich
sudo find /data/immich -name .immich -print | head
```

Then verify the application:

1. Open the target Immich web UI.
2. Sign in with the source machine's existing account credentials.
3. Confirm that all albums, users, faces, dates, and locations are present.
4. Open both thumbnails and full-size files.
5. Confirm that the server reports `/data/immich` as its media location.
6. Confirm that the target's media files are physically under `/data/immich` and not under `/DATA/.media/SSD-Storage`.

## 9. Verify the source and target are identical

While the source application remains stopped, run this command on the source:

```bash
sudo rsync -aHAX \
  --numeric-ids \
  --no-owner \
  --no-group \
  --checksum \
  --delete \
  --dry-run \
  --itemize-changes \
  /data/immich/ \
  "${TARGET_HOST}:/data/immich/"
```

No output means the source and target media trees are identical. The target should then be allowed to start normally, and the source should remain available for rollback until the new target has passed a full verification period.

## Rollback

If the target does not start or the migration is not correct:

1. Stop the target Immich services.
2. Leave the source machine stopped or running as needed for comparison.
3. Restore the target's pre-migration media directory if it existed:

```bash
# Run on the target
sudo systemctl stop immich-server immich-machine-learning
sudo rm -rf /data/immich
sudo if [ -e /data/immich-pre-migration ]; then
  sudo mv /data/immich-pre-migration /data/immich
  sudo chown -R immich:immich /data/immich
fi
```

4. Restore the target database from its pre-migration backup if one exists.
5. Resume the migration from Step 4 after resolving the failure.

## Cleanup

After the target has passed verification and the source has remained available for at least one week:

```bash
# Run on the source
sudo rm -f /data/immich-migration-dump.sql.gz

# Run on the target
sudo rm -f /root/immich-migration-dump.sql.gz
sudo rm -rf /data/immich-pre-migration
```

Keep the source's original `/data/immich` directory and the source's database backup until the target has been backed up independently. The target's final media directory remains `/data/immich`, on the RAID1-backed `/data` filesystem.
