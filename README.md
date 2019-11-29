# Docker + Consul + Vault

How to use docker-compose to spin up a Vault instance backed by Consul.

I just updated this repository, which is based of ideas from:
www.marcolancini.it/2017/blog-vault/

TODO: Fix Backup - it doesn't work for now

Note: In order to execute `scripts/vault_get_secret.py` you first need to source `env.sh` - assuming that you already imported the cert.
## Usage

#### Create certs (optional)

1. Create certs: `SAN=IP.1:127.0.0.1 scripts/gen-crt.sh`
2. Install and import certs to both container and host: `scripts/install-certs.sh`
3. Uncomment the part in vault.hcl about certificates and comment `tls_disable`
4. Restart the container if not already restarted 

#### First Run

1. Start services: `docker-compose up`
2. Init vault:     `./scripts/setup.sh`
3. When done:      `docker-compose down`

Data will be persisted in the `_data` folder.


#### Subsequent Runs

1. Start services: `docker-compose up`
2. Unseal vault:   `scripts/unseal.sh`


#### Backup

1. Start services: `docker-compose up`
2. Run backup:     `scripts/backup.sh`


#### Remove all data

1. Stop services: `docker-compose down --volumes`
2. Clear persisted data: `scripts/clean.sh`