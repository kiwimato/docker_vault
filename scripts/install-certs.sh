#!/bin/bash

# copy the certs to the container
docker cp tls/fullchain.crt vault:/usr/local/share/ca-certificates/vaultchain.crt
docker exec vault update-ca-certificates

# Install the certs on the Docker host
# Note: this only works on Linux, specifically tested on Red Hat flavors only.
sudp cp tls/fullchain.crt /etc/pki/ca-trust/source/anchors/vaultchain.crt
sudo update-ca-trust