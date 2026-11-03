# Immich Migration: ZimaOS (Docker) → NixOS (native module)

Tailored to your ZimaOS compose file (Immich **v2.7.2**). Follows the ordering rules in Immich's [backup docs](https://docs.immich.app/administration/backup-and-restore#backup-ordering): stop `immich-server`, dump the database, copy the files.

---

## Your setup (what this guide is built around)

| Item | Your value |
|---|---|
| DB container | `immich-postgres` |
| DB name / user / password | `immich` / `postgres` / `postgres` |
| Photos/videos (host path) | `/media/sdc-ata-WDC_WD42PURZ-85B_1/Gallery/immich` |
| Postgres data (host path) | `/media/sdc-ata-WDC_WD42PURZ-85B_1/AppData/immich/pgdata` (**not copied**, we use a dump) |
| ML model cache | `.../AppData/immich/model-cache` (**not copied**, re-downloads itself) |
| Web UI port | `8080` on ZimaOS → `2283` on NixOS |
| Extra containers | None. There is no `immich-microservices` in v2, and Redis is handled by NixOS. |

### Things that broke the old guide
1. The DB user is **`postgres`**, not `immich_user`.
2. Postgres must be **running** when you dump. Only stop `immich-server` and `immich-machine-learning`.
3. Don't stage photos in `/tmp` on ZimaOS. It's often RAM-backed and far too small. Copy straight from the data disk.
4. `cp -r upload/*` **skips hidden files**. Immich needs the `.immich` marker files inside each folder.
5. The database stores **file paths**. They must be rewritten to your NixOS media location (Step 6).
6. The NixOS Immich version must be **v2.7.2 or newer**. A dump can't be restored into an older Immich.

---

## Step 0: Set a few variables

Replace the values, then paste these into your terminal on each machine as needed.

**On ZimaOS:**
```bash
export NIXOS=youruser@192.168.1.50          # your NixOS SSH login + IP
export ZIMA_MEDIA=/media/sdc-ata-WDC_WD42PURZ-85B_1/Gallery/immich
export ZIMA_APPDATA=/media/sdc-ata-WDC_WD42PURZ-85B_1/AppData/immich
```

**On NixOS:**
```bash
export MEDIA=/data/immich                   # matches this repo's services.immich.mediaLocation
```

> Transfers can take hours. Run long commands inside `tmux` or `screen` so an SSH drop doesn't kill them.

---

## Step 1: Set up Immich on NixOS (ZimaOS keeps running)

Add this to your NixOS config (e.g. `immich.nix`) and rebuild:

```nix
services.immich = {
  enable = true;
  host = "0.0.0.0";
  port = 2283;
  openFirewall = true;
  mediaLocation = "/data/immich";      # matches this repo's Immich module
};
```

```bash
sudo nixos-rebuild switch
```

This installs Immich, Postgres (with the vector extensions) and Redis, and starts an empty Immich.

**Check the version is ≥ 2.7.2:**
```bash
systemctl cat immich-server | grep -oE 'immich-[0-9]+\.[0-9]+\.[0-9]+' | head -1
```
If it shows something older than `2.7.2`, update your nixpkgs (channel or flake input), rebuild, and check again. Newer is fine; Immich migrates the database automatically.

Then stop it and create a staging folder on the **same filesystem** as `$MEDIA`:
```bash
sudo systemctl stop immich-server immich-machine-learning
sudo mkdir -p ${MEDIA}-import
sudo chown $USER ${MEDIA}-import
```

---

## Step 2: Pre-copy photos while ZimaOS is still running (optional, cuts downtime)

**On ZimaOS:**
```bash
sudo rsync -aHv --info=progress2 --no-owner --no-group \
  "$ZIMA_MEDIA/" "$NIXOS:/data/immich-import/"
```
Note the **trailing slashes**. They copy the folder's contents, including hidden files. `sudo` makes ssh run as root, so it will ask for your NixOS password.

Skip this step if you'd rather do a single pass in Step 4.

---

## Step 3: Stop Immich on ZimaOS and dump the database

**On ZimaOS:**
```bash
# Stop only the app and ML. Postgres must keep running for the dump.
sudo docker stop immich-server immich-machine-learning

# Check which extensions the DB uses (for troubleshooting later)
sudo docker exec immich-postgres psql -U postgres -d immich -c '\dx'

# Dump. Note: no -t flag, it corrupts output when redirecting to a file.
sudo docker exec immich-postgres pg_dump --no-owner --no-privileges \
  --username=postgres --dbname=immich | gzip > "$ZIMA_APPDATA/immich-dump.sql.gz"

# Verify it
gzip -t "$ZIMA_APPDATA/immich-dump.sql.gz" && echo "gzip OK"
ls -lh "$ZIMA_APPDATA/immich-dump.sql.gz"
zcat "$ZIMA_APPDATA/immich-dump.sql.gz" | grep -c '^CREATE TABLE'    # should be dozens
```

The dump is saved on your data disk, not `/tmp`.

---

## Step 4: Transfer the files

**On ZimaOS:**
```bash
# Final sync of photos. After a pre-copy this only moves what changed.
sudo rsync -aHv --info=progress2 --no-owner --no-group --delete \
  "$ZIMA_MEDIA/" "$NIXOS:/data/immich-import/"

# The database dump (NIXOS should be root@<host>, matching the root shell on NixOS)
scp "$ZIMA_APPDATA/immich-dump.sql.gz" "$NIXOS:/root/immich-dump.sql.gz"
```

**Put the files in place on NixOS:**
```bash
# Empty the fresh install's media folder (it's brand new, nothing to lose)
sudo find $MEDIA -mindepth 1 -delete

# Move everything in, hidden files included
sudo find ${MEDIA}-import -mindepth 1 -maxdepth 1 -exec mv -t $MEDIA/ {} +

sudo chown -R immich:immich $MEDIA

# Sanity check: you should see upload, library, thumbs, profile, etc., each with a .immich file
ls -la $MEDIA
ls -la $MEDIA/upload | head
```

> The dump lands at `/root/immich-dump.sql.gz` on NixOS. Step 5 runs as root and reads it from that path. This assumes `$NIXOS` connects as `root`; if you use a different SSH account, adjust the `scp` destination and restore path to match.

---

## Step 5: Restore the database on NixOS

Immich's restore needs a **fresh** database that has never been used, so we recreate it. We temporarily make the `immich` DB user a superuser so it can create the vector extensions and own everything it restores.

```bash
# 1. Recreate an empty database
sudo -u postgres psql -c 'DROP DATABASE immich;'
sudo -u postgres psql -c 'CREATE DATABASE immich OWNER immich;'
sudo -u postgres psql -c 'ALTER USER immich WITH SUPERUSER;'

# 2. Restore (this is Immich's documented command, adapted for NixOS)
zcat /root/immich-dump.sql.gz \
  | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
  | sudo -u immich psql -d immich --single-transaction --set ON_ERROR_STOP=on

# 3. Remove the temporary superuser rights
sudo -u postgres psql -c 'ALTER USER immich WITH NOSUPERUSER;'
```

The restore runs in one transaction. If anything fails, nothing is half-applied, so you can fix the problem and retry from step 1. See the troubleshooting table at the bottom.

---

## Step 6: Let Immich migrate media paths

Immich v1.136.0 and newer migrates database paths automatically when the media location changes. The NixOS module in this guide uses Immich v2.7.5 or newer, so do not manually rewrite path columns in the database.

Before starting Immich, make sure the complete media tree has been copied into `$MEDIA` and that `services.immich.mediaLocation` matches it. On startup, Immich detects the previous location saved in the database and updates paths to the configured location. Keep the staging copy until startup and media verification succeed.

If startup reports an inconsistent media location, stop Immich and check the configured media location and database paths. Do not move files or manually rewrite database paths to work around the error; see the troubleshooting table below.

---

## Step 7: Start Immich and verify

```bash
sudo systemctl start immich-server immich-machine-learning
journalctl -u immich-server -f
```

Open `http://<nixos-ip>:2283` and log in with your **old** credentials. Check:

- Photos and videos open (thumbnails **and** full-size).
- Albums, people/faces, and users are there.
- Dates and map locations are correct.
- Smart search works (the ML models download on first use, which can take a few minutes).

**Phone app:** change the server URL to `http://<nixos-ip>:2283`. Your backup history is tied to the server account, so it won't re-upload everything.

---

## Rollback (ZimaOS is untouched)

Nothing has been deleted from ZimaOS. If something goes wrong:
```bash
sudo docker start immich-server immich-machine-learning
```

Keep ZimaOS's data as your backup for a week or two before deleting anything.

---

## Troubleshooting

| Problem | Cause / fix |
|---|---|
| `extension "vectors" is not available` during restore | Your old DB still has the legacy pgvecto.rs extension, which NixOS doesn't ship. Strip it from the dump and retry from Step 5: `zcat dump.sql.gz \| grep -v -i 'EXTENSION.*vectors' \| gzip > dump-clean.sql.gz`. If it then fails on a `vectors` column type, stop and ask for help with the `\dx` output from Step 3. |
| `role "postgres" does not exist` or ownership errors | Re-run the dump with `--no-owner --no-privileges` (Step 3 already does). |
| `relation already exists` | The DB wasn't fresh. Repeat Step 5 from `DROP DATABASE`. |
| Web UI loads but images/thumbnails are broken | Paths not fixed or wrong prefix. Redo Step 6, then confirm the files exist with `ls $MEDIA/upload`. |
| `Failed to read .immich` / folder integrity errors | Hidden marker files missing. Re-run the rsync in Step 4 and confirm `ls -la $MEDIA/thumbs` shows `.immich`. |
| Permission denied errors in logs | `sudo chown -R immich:immich $MEDIA` |
| Server won't start after restore | `journalctl -u immich-server -n 100 --no-pager`. A version older than 2.7.2 shows up here as a migration error (see Step 1). |
| Permission errors on the DB after Step 5 | Rare. Re-run `sudo -u postgres psql -c 'ALTER USER immich WITH SUPERUSER;'` and restart Immich. |
| Can't reach the UI from another device | `openFirewall = true` and `host = "0.0.0.0"` in the config, then rebuild. Note the new port is 2283, not 8080. |

---

## Cleanup (after a week or two of everything working)

**NixOS:**
```bash
sudo rm -rf /data/immich-import /root/immich-dump.sql.gz
```

**ZimaOS:** once you're sure, remove the dump and (optionally) the old containers and data:
```bash
rm "$ZIMA_APPDATA/immich-dump.sql.gz"
```
Keep the original `Gallery/immich` folder until you have another backup of your photos (3-2-1 rule).