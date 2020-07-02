#!/bin/bash

source hvault-deploy/hvault_common.sh \
  VAULT_CONSUMER_AWS_PROFILE_$1 \
  VAULT_CONSUMER_AWS_ACCOUNT_ID_$1 \
  VAULT_CONSUMER_NAMESPACE_$1 \
  VAULT_CONSUMER_ROLE_ARN_$1 \
  VAULT_SERVICE_URL


VAULT_CONSUMER_AWS_PROFILE=VAULT_CONSUMER_AWS_PROFILE_$1
VAULT_CONSUMER_AWS_ACCOUNT_ID=VAULT_CONSUMER_AWS_ACCOUNT_ID_$1
VAULT_CONSUMER_NAMESPACE=VAULT_CONSUMER_NAMESPACE_$1
VAULT_CONSUMER_ROLE_ARN=VAULT_CONSUMER_ROLE_ARN_$1

VAULT_STACKNAME=hvault-auth
VAULT_CONSUMER_AWS_BUCKET="${VAULT_STACKNAME}-${!VAULT_CONSUMER_AWS_ACCOUNT_ID}-$$"
VAULT_CONSUMER_AWS_PROFILE="VAULT_CONSUMER_AWS_PROFILE_$1"
VAULT_CONSUMER_AWS_REGION=`aws configure get region --profile "${!VAULT_CONSUMER_AWS_PROFILE}"`


aws s3api create-bucket \
  --bucket "$VAULT_CONSUMER_AWS_BUCKET" \
  --region "$VAULT_CONSUMER_AWS_REGION" \
  --profile "${!VAULT_CONSUMER_AWS_PROFILE}"

echo "Starting SAM Build..."

BUILD_ROOT=hvault-aws-auth

cd $PROJECT_ROOT && \
sam build \
    --profile "${!VAULT_CONSUMER_AWS_PROFILE}" \
    --template hvault-aws-auth/hvault-aws-auth-template.yaml \
    --build-dir hvault-aws-auth/.aws-sam/build \
    --use-container

cd $PROJECT_ROOT && \
sam package \
    --profile "${!VAULT_CONSUMER_AWS_PROFILE}" \
    --template-file hvault-aws-auth/.aws-sam/build/template.yaml \
    --output-template-file hvault-aws-auth/.aws-sam/build/packaged-template.yaml \
    --s3-bucket "$VAULT_CONSUMER_AWS_BUCKET"

cd $PROJECT_ROOT && \
sam deploy \
  --profile "${!VAULT_CONSUMER_AWS_PROFILE}" \
  --region "$VAULT_CONSUMER_AWS_REGION" \
  --template-file hvault-aws-auth/.aws-sam/build/packaged-template.yaml \
  --stack-name "$VAULT_STACKNAME" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --confirm-changeset \
  --parameter-overrides \
     VaultAccountId="$VAULT_SERVICE_AWS_ACCOUNTID" \
     VaultKvMount=kv \
     VaultSkipVerify=true \
     VaultAddr="$VAULT_SERVICE_URL" \
     VaultNamespace="${!VAULT_CONSUMER_NAMESPACE}" \
     VaultOption3RoleArn="${!VAULT_CONSUMER_ROLE_ARN}"

echo "Run the following commands to populate the variables for stage 3"

echo ./hvault.sh -s hvault-auth HVaultAccessFunctionIamRole VAULT_OPT1_CONSUMER_ROLE_ARN_$1
