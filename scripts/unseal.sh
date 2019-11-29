#!/bin/bash

## CONFIG LOCAL ENV
echo "[*] Config local environment..."
export VAULT_OPT="-address=http://127.0.0.1:8200"

function unseal () {
  export VAULT_CMD='docker exec vault vault'
  $VAULT_CMD operator unseal $1 "$(grep 'Key 1:' ./_data/keys.txt | awk '{print $NF}')" > /tmp/vault.log 2>&1
  $VAULT_CMD operator unseal $1 "$(grep 'Key 2:' ./_data/keys.txt | awk '{print $NF}')" >> /tmp/vault.log 2>&1
  $VAULT_CMD operator unseal $1 "$(grep 'Key 3:' ./_data/keys.txt | awk '{print $NF}')" >> /tmp/vault.log 2>&1
}

## UNSEAL VAULT
if vault status -address=http://127.0.0.1:8200 2>&1 | grep -q 'Client sent an HTTP request to an HTTPS server'; then
  echo "[*] Looks like SSL is enabled. Awesome!"
  unseal
  if grep -q 'certificate signed by unknown authority' /tmp/vault.log; then
    echo "Looks like the certificate gotgot reverted, copying it back to the container"
    docker cp tls/fullchain.crt vault:/usr/local/share/ca-certificates/vaultchain.crt
    docker exec vault update-ca-certificates
    echo "Trying to unseal again"
    unseal && echo Success || echo Failed
  else
    cat /tmp/vault.log
  fi
else
  echo "[*] Unseal vault..."
  unseal ${VAULT_OPT}
fi