# Garage

Single-node S3-compatible object storage. See `setup.sh` for first-run bootstrap
(layout assign/apply, initial key + bucket).

All commands below run the `garage` binary inside the running container — there's
no need to install the CLI on the host:

```bash
docker exec garage /garage <command>
```

## Cluster status

```bash
# Node ID, cluster health, layout status
docker exec garage /garage status

# Current layout (zones, capacities, assigned nodes)
docker exec garage /garage layout show

# Storage usage stats
docker exec garage /garage stats
```

Layout changes (`layout assign` / `layout apply`) are only needed once, at first
bootstrap — see `setup.sh`. A single-node cluster never needs them again unless
you change the node's storage capacity.

## Buckets

```bash
# List all buckets
docker exec garage /garage bucket list

# Create a bucket
docker exec garage /garage bucket create my-bucket

# Show a bucket's info (size, website config, key grants)
docker exec garage /garage bucket info my-bucket

# Delete an empty bucket
docker exec garage /garage bucket delete my-bucket

# Give a bucket an extra alias name
docker exec garage /garage bucket alias my-bucket my-alias
```

## Access keys

Garage has no root/admin S3 user like MinIO's `ADMIN_USER`/`ADMIN_PASSWORD` —
every client connects with a scoped access key.

```bash
# Create a new key (prints the Key ID and Secret Access Key — save the secret, it's only shown once)
docker exec garage /garage key create backup-key

# List keys
docker exec garage /garage key list

# Show a key's info and which buckets it can access
docker exec garage /garage key info backup-key

# Delete a key
docker exec garage /garage key delete backup-key
```

## Granting bucket access

```bash
# Grant read+write+owner on a bucket to a key
docker exec garage /garage bucket allow --read --write --owner my-bucket --key backup-key

# Revoke access
docker exec garage /garage bucket deny --read --write my-bucket --key backup-key
```

A key only sees buckets it's been explicitly granted — there's no equivalent of
MinIO's root user that sees everything by default.
