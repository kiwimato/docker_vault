## CONFIG LOCAL ENV
echo "[*] Config local environment..."
VAULT_CMD='docker exec vault vault'
KEYS_FILE='./_data/keys.txt'

# If SSL is enabled we don't need the address field
if $(vault status -address=http://127.0.0.1:8200 2>&1| grep -q 'Client sent an HTTP request to an HTTPS server'); then
  VAULT_TLS_ARG=""
else
  VAULT_TLS_ARG='-address=http://127.0.0.1:8200'
fi

## INIT VAULT
if [[ ! -f $KEYS_FILE ]] || [[ "$(grep 'Key 1:' ${KEYS_FILE} | awk '{print $NF}')" == "" ]]; then
  echo "[*] Init vault..."
  $VAULT_CMD operator init ${VAULT_TLS_ARG} > ${KEYS_FILE}
else
  echo "[*] Vault already initialized, skipping init."
fi

export VAULT_TOKEN=$(grep 'Initial Root Token:' ${KEYS_FILE} | awk '{print $NF}')

## UNSEAL VAULT
VAULT_SEAL_STATUS="$($VAULT_CMD status ${VAULT_TLS_ARG} | grep ^Sealed | awk '{print $NF}')"
if [[ "${VAULT_SEAL_STATUS}" == "true" ]]; then
  echo "[*] Unsealing vault..."
  $VAULT_CMD operator unseal ${VAULT_TLS_ARG} $(grep 'Key 1:' ${KEYS_FILE} | awk '{print $NF}')
  $VAULT_CMD operator unseal ${VAULT_TLS_ARG} $(grep 'Key 2:' ${KEYS_FILE} | awk '{print $NF}')
  $VAULT_CMD operator unseal ${VAULT_TLS_ARG} $(grep 'Key 3:' ${KEYS_FILE} | awk '{print $NF}')
else
  echo "[*] Vault already unsealed, no need to unseal"
fi

## AUTH
echo "[*] Auth..."
$VAULT_CMD login ${VAULT_TLS_ARG} ${VAULT_TOKEN}

## CREATE USER
echo "[*] Enabling AppRole auth"
curl -s\
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    http://127.0.0.1:8200/v1/sys/auth/approle

echo "[*] Create ACL policies under AppRole: dev-policy, my-policy, 3dhubs-policy"
curl -s\
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"policies": ["dev-policy", "my-policy", "3dhubs-policy"]}' \
    http://127.0.0.1:8200/v1/auth/approle/role/my-role

echo "[*] Create role_id under my-role"
curl -s\
    --header "X-Vault-Token: $VAULT_TOKEN" \
     http://127.0.0.1:8200/v1/auth/approle/role/my-role/role-id | jq

echo "[*] Create secret_id under my-role"
curl -s\
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    http://127.0.0.1:8200/v1/auth/approle/role/my-role/secret-id | jq

## CREATE BACKUP TOKEN
echo "[*] Create backup token..."
$VAULT_CMD token create ${VAULT_TLS_ARG} -display-name="backup_token" | awk '/token/{i++}i==2' | awk '{print "backup_token: " $2}' >> ${KEYS_FILE}

### READ/WRITE
# $ vault write ${VAULT_TLS_ARG} secret/api-key value=12345678
# $ vault read ${VAULT_TLS_ARG} secret/api-key