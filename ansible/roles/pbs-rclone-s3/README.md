pbs-rclone-s3
=============

Runs `rclone serve s3` on the Proxmox Backup Server host. It is backed by an rclone `crypt` remote on a Google Shared Drive. PBS (4.2 or later) uses it as an S3 datastore backend at `https://127.0.0.1:8443`.

What the role does:

- Installs the pinned upstream rclone `.deb`. Debian trixie ships 1.60.1, but `serve s3` needs 1.65 or later.
- Generates a self-signed TLS cert for `127.0.0.1`. PBS refuses plain HTTP and pins the cert fingerprint.
- Deploys a hardened `rclone-s3.service`:
  - `DynamicUser`, `ProtectSystem=strict`, a syscall filter, and bind restricted to the S3 port.
  - Secrets passed through `LoadCredential=`, never on argv.
- Creates the bucket and the PBS S3 endpoint `gdrive-crypt`.
- Optionally creates the datastore.

Requirements
------------

1. Create a Google Cloud service account and a JSON key for it.
2. Add the service account to the Shared Drive as **Content manager**. Manager is not needed, because deletes go to trash.
3. Set `pbs_rclone_s3_shared_drive_id` in the playbook or inventory. The ID is the last part of the Shared Drive URL.
4. Create `ansible/secrets/pbs-rclone-s3.sops.yml` with `sops ansible/secrets/pbs-rclone-s3.sops.yml`:

```yaml
gdrive_service_account:      # SA JSON key, as a YAML map
    type: service_account
    project_id: ...
    private_key_id: ...
    private_key: |
        -----BEGIN PRIVATE KEY-----
        ...
    client_email: ...@....iam.gserviceaccount.com
    client_id: "..."           # quote it: the 21-digit ID loses precision as a YAML number
    token_uri: https://oauth2.googleapis.com/token
crypt_password_obscured: ...   # rclone obscure '<password>'
crypt_password2_obscured: ...  # rclone obscure '<salt>'
s3_access_key: ...             # openssl rand -hex 16
s3_secret_key: ...             # openssl rand -hex 32
```

The crypt passwords are stored already obscured. `rclone obscure` uses a random IV, so obscuring them at deploy time would change the config on every run.

**Also store the plaintext crypt password and salt offline.** If you lose them, every backup is lost.

Role Variables
--------------

See `defaults/main.yml`. The main ones:

| Variable | Default | Notes |
|---|---|---|
| `pbs_rclone_s3_shared_drive_id` | `""` | Required |
| `pbs_rclone_s3_version` | `1.75.2` | Renovate bumps it. The download is checked against that release's `SHA256SUMS`. |
| `pbs_rclone_s3_drive_root` | `pbs-s3` | Drive folder that holds the encrypted data |
| `pbs_rclone_s3_bucket` | `pbs` | |
| `pbs_rclone_s3_rotate_secret` | `false` | Force-pushes the sops access and secret key to the PBS endpoint. Done automatically when `auth-key` changes. |
| `pbs_rclone_s3_create_datastore` | `false` | See below |

Datastore
---------

Datastore creation is one-shot, so it is opt-in. Do it by hand:

1. Put the local cache on a dedicated dataset with a 64–128 GiB quota:

    ```sh
    zfs create -o quota=128G rpool/gdrive-cache   # mounted at /mnt/datastore/gdrive-cache
    ```

2. Create the datastore:

    ```sh
    proxmox-backup-manager datastore create gdrive /mnt/datastore/gdrive-cache \
        --backend type=s3,client=gdrive-crypt,bucket=pbs
    ```

3. Use it as a sync target for a small set of important backups, not as the primary store.

Risks and limits
----------------

- **Shared Drive item limit.** A Shared Drive holds at most 400,000 files and folders. PBS stores one object per chunk, and the `.chunks/<4hex>` prefixes alone can use up to 65,536 folders. The store therefore tops out at roughly 0.5–1 TiB of deduplicated data. When the limit is hit, backups fail.
- **Throughput.** Drive manages about 2 small files per second and caps uploads at 750 GB/day (`stop_on_upload_limit` makes the cap fail fast). A first full backup of several hundred GiB takes days.
- **Trash.** Deletes go to the Shared Drive trash (`use_trash = true`), because a Content manager cannot delete permanently. Trashed chunks count toward the item limit until Drive purges them after 30 days, but give a 30-day undo window.
- **Garbage collection and verify jobs** list every chunk, which takes hours. Schedule them sparingly.
- rclone ignores `If-None-Match`, so a re-uploaded chunk creates a new Drive revision. Revisions are kept for about 30 days.
- Concurrent writes to the same key can create duplicate filenames. Stop the service, then run `rclone dedupe`.
- `rclone serve s3` is experimental, and it keeps object metadata in memory only.
- rclone is installed outside apt, so unattended-upgrades does not update it. Merge the Renovate PRs.

Verification
------------

```sh
systemctl status rclone-s3
systemd-analyze security rclone-s3.service
ss -ltnp | grep 8443                                   # 127.0.0.1 only
tr '\0' ' ' </proc/$(pidof rclone)/cmdline              # no secrets
proxmox-backup-manager s3 endpoint list
proxmox-backup-manager s3 check gdrive-crypt pbs
```

Recovery drill: on another machine, rebuild `rclone.conf` from the sops values. Then run `rclone lsd gdrive-crypt:pbs` and restore a backup.

License
-------

MIT-0
