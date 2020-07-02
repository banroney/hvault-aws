#!/bin/bash

source hvault-deploy/hvault_common.sh \
  VAULT_SECRETS_STORE_NUMBER \
  VAULT_SECRETS_THRESHOLD_NUMBER \
  VAULT_RECOVERY_STORE_NUMBER \
  VAULT_RECOVERY_THRESHOLD_NUMBER \
  VAULT_ECS_DESIRED_CAP \
  VAULT_ECS_MAX_CAP \
  VAULT_DYNAMO_HA_ENABLED \
  VAULT_DOCKER_IMAGE_TAG \
  VAULT_CLIENT_DOCKER_IMAGE_TAG \
  VAULT_KMS_ADMIN_ARN \
  VAULT_CERTIFICATE_ARN \
  VAULT_VPC_ID \
  VAULT_ECS_SUBNETS \
  VAULT_ALB_SUBNETS \
  VAULT_SERVICE_OPTION3_ROLE_PREFIX \
  VAULT_SERVICE_PROFILE

template_file=`ls $PWD/hvault-svc/hvault-svc-template.yaml`

if [ -e $template_file ]
  then
    aws cloudformation create-stack \
    --profile $VAULT_SERVICE_PROFILE \
    --stack-name hvault-svc \
    --template-body file://$template_file \
    --parameters \
      ParameterKey=VaultSecretsStore,ParameterValue=$VAULT_SECRETS_STORE_NUMBER \
      ParameterKey=VaultSecretsThreshold,ParameterValue=$VAULT_SECRETS_THRESHOLD_NUMBER \
      ParameterKey=VaultRecoveryStore,ParameterValue=$VAULT_RECOVERY_STORE_NUMBER \
      ParameterKey=VaultRecoveryThreshold,ParameterValue=$VAULT_RECOVERY_THRESHOLD_NUMBER \
      ParameterKey=VaultInitiatorImageTag,ParameterValue=$VAULT_CLIENT_DOCKER_IMAGE_TAG \
      ParameterKey=VaultImageTag,ParameterValue=$VAULT_DOCKER_IMAGE_TAG \
      ParameterKey=HVaultKmsAutoUnsealKeyAdmin,ParameterValue=$VAULT_KMS_ADMIN_ARN \
      ParameterKey=EndpointCertificate,ParameterValue=$VAULT_CERTIFICATE_ARN \
      ParameterKey=VpcId,ParameterValue=$VAULT_VPC_ID \
      ParameterKey=ECSSubnetIds,ParameterValue=$VAULT_ECS_SUBNETS \
      ParameterKey=ALBSubnetIds,ParameterValue=$VAULT_ALB_SUBNETS \
      ParameterKey=DesiredCapacity,ParameterValue=$VAULT_ECS_DESIRED_CAP \
      ParameterKey=MaxSize,ParameterValue=$VAULT_ECS_MAX_CAP \
      ParameterKey=HAEnabled,ParameterValue=$VAULT_DYNAMO_HA_ENABLED \
      ParameterKey=VaultOption3RolePrefix,ParameterValue=$VAULT_SERVICE_OPTION3_ROLE_PREFIX \
      ParameterKey=VaultConsumerNamespace1,ParameterValue=$VAULT_CONSUMER_NAMESPACE_1 \
      ParameterKey=VaultAWSAccountID1,ParameterValue=$VAULT_CONSUMER_AWS_ACCOUNT_ID_1 \
      ParameterKey=VaultConsumerNamespace2,ParameterValue=$VAULT_CONSUMER_NAMESPACE_2 \
      ParameterKey=VaultAWSAccountID2,ParameterValue=$VAULT_CONSUMER_AWS_ACCOUNT_ID_2 \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM"
fi

echo "Run the following commands to populate the variables for stage 2"

echo ./hvault.sh -s hvault-svc HVaultECSEndpoint VAULT_SERVICE_URL
echo ./hvault.sh -s hvault-svc HVaultOption3RoleConsumer1 VAULT_CONSUMER_ROLE_ARN_1
echo ./hvault.sh -s hvault-svc HVaultOption3RoleConsumer2 VAULT_CONSUMER_ROLE_ARN_2
echo ./hvault.sh -s hvault-svc HVaultRootToken VAULT_SERVICE_TOKEN_SECRET_ARN


#./hvault.sh -s hvault-svc HVaultECSEndpoint VAULT_SERVICE_URL
#./hvault.sh -s hvault-svc HVaultOption3RoleConsumer1 VAULT_CONSUMER_ROLE_ARN_1
#./hvault.sh -s hvault-svc HVaultOption3RoleConsumer2 VAULT_CONSUMER_ROLE_ARN_1




