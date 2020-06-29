#!/bin/sh

while :
do
	http_stat=`curl -k -s -o /tmp/http_stat.out -w "%{http_code}" $VAULT_ADDR/v1/sys/seal-status`
  if [[ $http_stat == '200' ]]; then
    echo 'Vault is running. Checking if initialized...'
    is_initilized=`cat /tmp/http_stat.out|jq ".initialized"`
    if [[ $is_initilized == 'true' ]]; then
      echo  'Vault is already initialized.'
      exit
    else
      echo  'Starting Initialization.'
      echo "{\"secret_shares\": $VAULT_SECRETS_S,\"secret_threshold\": $VAULT_SECRETS_T, \"recovery_shares\": $VAULT_RECOVERY_S, \"recovery_threshold\": $VAULT_RECOVERY_T }"> /tmp/http_init_post.json
      http_init=`curl -k -s -w '%{http_code}' --location --request PUT -o /tmp/http_init.out $VAULT_ADDR/v1/sys/init --header 'Content-Type: application/json' -d  @/tmp/http_init_post.json`
      if [[ $http_init == '200' ]]; then
        root_token=`cat /tmp/http_init.out | jq ".root_token"`
        recovery_keys=`cat /tmp/http_init.out | jq ".recovery_keys_base64"| sed 's/"/\\"/g'`
        echo 'Store super secret keys in AWS Secret Manager'
        aws secretsmanager update-secret --secret-id $AWS_SM_ROOT_TOKEN --secret-string "{\"root_token\":$root_token}"
        aws secretsmanager update-secret --secret-id $AWS_SM_RECOVERY_KEYS --secret-string "{\"recovery_keys\":$recovery_keys}"
        echo 'Completed Initialization.'
      else
        echo  'Failed Initialization. Try manually'
      fi
      exit
    fi
  else
    echo 'Vault is not running. Trying again'
  fi
	sleep 5
done


