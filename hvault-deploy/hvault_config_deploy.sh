#!/bin/bash

source hvault-deploy/hvault_common.sh \
  VAULT_CONSUMER_AWS_ACCOUNT_ID_$1 \
  VAULT_CONSUMER_NAMESPACE_$1 \
  VAULT_CONSUMER_ROLE_ARN_$1 \
  VAULT_SERVICE_URL


VAULT_CONSUMER_AWS_ACCOUNT_ID=VAULT_CONSUMER_AWS_ACCOUNT_ID_$1
VAULT_CONSUMER_NAMESPACE=VAULT_CONSUMER_NAMESPACE_$1
VAULT_CONSUMER_ROLE_ARN=VAULT_CONSUMER_ROLE_ARN_$1
VAULT_CONSUMER_OPT1_ROLE_ARN=VAULT_CONSUMER_OPT1_ROLE_ARN_$1


VAULT_SERVICE_TOKEN=`aws secretsmanager get-secret-value --secret-id "$VAULT_SERVICE_TOKEN_SECRET_ARN" |jq -r ".SecretString" |jq -r ".root_token"`


echo $input_file
config_file="./hvault-deploy/config/hvault_postman.json"
config_generated_file="./hvault-deploy/local-data/hvault_postman_nsgen.json"

cp $config_file $config_generated_file

cat $config_file | sed  "s,\$VAULT_CONSUMER_NAMESPACE,${!VAULT_CONSUMER_NAMESPACE},g"  \
                 |  sed  "s,\$VAULT_CONSUMER_AWS_ACCOUNT_ID,${!VAULT_CONSUMER_AWS_ACCOUNT_ID},g"  \
                 |  sed  "s,\$VAULT_CONSUMER_ROLE_ARN,${!VAULT_CONSUMER_ROLE_ARN},g"  \
                 |  sed  "s,\$VAULT_CONSUMER_OPT1_ROLE_ARN,${!VAULT_CONSUMER_OPT1_ROLE_ARN},g"  \
                 |  sed  "s,\$VAULT_SERVICE_URL,${VAULT_SERVICE_URL},g"  \
                 |  sed  "s,\$VAULT_SERVICE_TOKEN,${VAULT_SERVICE_TOKEN},g"  > $config_generated_file


echo "Running Newman to configure Vault at $VAULT_SERVICE_URL"
newman run $config_generated_file -k
rm -rf $config_generated_file
