# Matrix

LAN-only Matrix chat: Synapse homeserver at `https://matrix.<hostname>.duckdns.org`,
Element Web client at `https://element.<hostname>.duckdns.org`. Federation is off.
See `setup.sh` for first-run setup.

## Creating users

Open registration is disabled (`enable_registration: false`), so accounts can only
be created from the NAS with the `register_new_matrix_user` tool bundled in the
Synapse image:

```bash
docker exec -it matrix_synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
```

It prompts for a username, a password, and whether the user should be an admin.
To skip the prompts:

```bash
docker exec -it matrix_synapse register_new_matrix_user -c /data/homeserver.yaml \
    -u alice -p 'their-password' --no-admin http://localhost:8008
```

Use `--admin` instead of `--no-admin` for an admin account. The first user you
create should be an admin.

`-c /data/homeserver.yaml` is where the tool reads the `registration_shared_secret`
that Synapse generated during `setup.sh`. Only someone with shell access to the
container has it, which is what keeps account creation admin-only.

## Signing in

The new user's ID is `@alice:<hostname>.duckdns.org`. They sign in at
`https://element.<hostname>.duckdns.org` with the username and password. They can
change the password afterwards in Element's settings.

## Backups

`backup.sh` dumps the Synapse database (`pg_dump`, safe while running) into
`$MATRIX_DATA_DIR/dumps/` and keeps the newest 14 dumps (`MATRIX_BACKUP_KEEP` to
change). A dump is only kept, and old ones only pruned, if `pg_restore` can read it.

```bash
MATRIX_DATA_DIR=/mnt/hddpool/matrix ./matrix/backup.sh
```

Run it on a schedule (cron / TrueNAS cron job) before your regular backup of
`/mnt/hddpool/matrix`, which then picks up the dumps alongside `synapse/`
(generated secrets, signing key, uploaded media).

To restore, start only Postgres against an empty data dir, load the dump, then
start the stack:

```bash
cd matrix
docker compose --env-file ../.env -f docker-compose.yml -f docker-compose.override.yml up -d postgres
docker exec -i matrix_postgres pg_restore -U synapse -d synapse --no-owner < /mnt/hddpool/matrix/dumps/synapse-<timestamp>.dump
./up.sh
```
