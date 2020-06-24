#!/bin/bash

cd $PROJECT_ROOT



while read -r line; do
  if [[ $line =~ ^(.*)=(.*)$  ]]; then
    export "$line"
  fi
done < ./hvault-setup/template_vals.env

echo "$VAULT_CONSUMER_AWS_PROFILE"
echo "$VAULT_CONSUMER_AWS_BUCKET"
echo "$VAULT_CONSUMER_AWS_REGION"
echo "$VAULT_CONSUMER_AWS_ACCOUNTID"
echo "$VAULT_CONSUMER_NAMESPACE"
echo "$VAULT_CONSUMER_ROLE_ARN"

echo "$VAULT_SERVICE_AWS_ACCOUNTID"
echo "$VAULT_SERVICE_URL"
echo "$VAULT_SERVICE_TOKEN"
echo "$VAULT_SERVICE_OPTION3_ROLE_ARN"

aws s3api create-bucket --bucket "$VAULT_CONSUMER_AWS_BUCKET" --region "$VAULT_CONSUMER_AWS_REGION"

echo "Starting SAM Build"

sam build \
    --profile "$VAULT_CONSUMER_AWS_PROFILE" \
    --template template.yaml \
    --build-dir .aws-sam/build \
    --use-container

sam package \
    --profile "$VAULT_CONSUMER_AWS_PROFILE" \
    --template-file .aws-sam/build/template.yaml \
    --output-template-file .aws-sam/build/packaged-template.yaml \
    --s3-bucket "$VAULT_CONSUMER_AWS_BUCKET"

sam deploy \
  --profile "$VAULT_CONSUMER_AWS_PROFILE" \
  --region "$VAULT_CONSUMER_AWS_REGION" \
  --template-file .aws-sam/build/packaged-template.yaml \
  --stack-name hvault-aws \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --confirm-changeset \
  --parameter-overrides \
     VaultAccountId="$VAULT_SERVICE_AWS_ACCOUNTID" \
     VaultKvMount=kv \
     VaultSkipVerify=true \
     VaultAddr="$VAULT_SERVICE_URL" \
     VaultNamespace="$VAULT_CONSUMER_NAMESPACE" \
     VaultOption3RoleArn="$VAULT_SERVICE_OPTION3_ROLE_ARN"