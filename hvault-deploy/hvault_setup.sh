#!/bin/bash
cd $PROJECT_ROOT

while read -r line; do
  if [[ $line =~ ^(.*)=(.*)$  ]]; then
    export "$line"
  fi
done < ./hvault-setup/template_vals.env

envsubst < ./hvault-setup/hvault_postman.json > ./hvault-setup/__hvault_postman_nsgen__.json


echo "Running Newman to configure Vault at $VAULT_SERVICE_URL"
newman run ./hvault-setup/__hvault_postman_nsgen__.json -k
rm -rf ./hvault-setup/__hvault_postman_nsgen__.json
