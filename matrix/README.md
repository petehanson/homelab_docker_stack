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
