#!/bin/bash

while read -r line; do export  "$line"; done <./template_vals.env
envsubst < ./hvault_postman.json > ./hvault_postman_nsgen.json


echo "Running Newman to configure Vault at $VAULT_URL"
newman run ./hvault_postman_nsgen.json -k
rm -rf ./hvault_postman_nsgen.json
