#!/bin/bash
set -e
if [ -z "$PROJECT_ROOT" ]
then
      echo "\$PROJECT_ROOT is empty"
      exit
fi

echo "cd to $PROJECT_ROOT"

input_file=hvault-deploy/local-data/val.env
input_template=hvault-deploy/config/template_vals.sample


cd $PROJECT_ROOT

if [ -e $input_file ]
then
    echo "Input file exists, continuing setup..."

else
    echo Input File doesnt exist. Creating input file "$input_file". Please provide the following mandatory
    mkdir -p `dirname "$input_file"` && cp $input_template $input_file

    # Filling up mandatory values
    read -p "VAULT_SERVICE_AWS_ACCOUNTID : " a_VAULT_SERVICE_AWS_ACCOUNTID
    read -p "VAULT_CLIENT_DOCKER_IMAGE_TAG : " a_VAULT_CLIENT_DOCKER_IMAGE_TAG
    read -p "VAULT_KMS_ADMIN_ARN : " a_VAULT_KMS_ADMIN_ARN
    read -p "VAULT_CERTIFICATE_ARN : " a_VAULT_CERTIFICATE_ARN
    read -p "VAULT_VPC_ID : " a_VAULT_VPC_ID
    read -p "VAULT_ECS_SUBNETS : " a_VAULT_ECS_SUBNETS
    read -p "VAULT_ALB_SUBNETS : " a_VAULT_ALB_SUBNETS
    echo
    echo Fill up the following for Stage 2,3 and 4
    read -p "VAULT_CONSUMER_AWS_PROFILE_1 : " a_VAULT_CONSUMER_AWS_PROFILE_1
    read -p "VAULT_CONSUMER_AWS_ACCOUNT_ID_1 : " a_VAULT_CONSUMER_AWS_ACCOUNT_ID_1
    read -p "VAULT_CONSUMER_NAMESPACE_1 : " a_VAULT_CONSUMER_NAMESPACE_1
    read -p "VAULT_CONSUMER_AWS_PROFILE_2 : " a_VAULT_CONSUMER_AWS_PROFILE_2
    read -p "VAULT_CONSUMER_AWS_ACCOUNT_ID_2 : " a_VAULT_CONSUMER_AWS_ACCOUNT_ID_2
    read -p "VAULT_CONSUMER_NAMESPACE_2 : " a_VAULT_CONSUMER_NAMESPACE_2

    sed -i -n -e "s,^\(VAULT_SERVICE_AWS_ACCOUNTID\)\(=\)\(.*\),\1\2${a_VAULT_SERVICE_AWS_ACCOUNTID},g;
               s,^\(VAULT_CLIENT_DOCKER_IMAGE_TAG\)\(=\)\(.*\),\1\2${a_VAULT_CLIENT_DOCKER_IMAGE_TAG},g;
               s,^\(VAULT_KMS_ADMIN_ARN\)\(=\)\(.*\),\1\2${a_VAULT_KMS_ADMIN_ARN},g;
               s,^\(VAULT_CERTIFICATE_ARN\)\(=\)\(.*\),\1\2${a_VAULT_CERTIFICATE_ARN},g;
               s,^\(VAULT_VPC_ID\)\(=\)\(.*\),\1\2${a_VAULT_VPC_ID},g;
               s,^\(VAULT_ECS_SUBNETS\)\(=\)\(.*\),\1\2${a_VAULT_ECS_SUBNETS},g;
               s,^\(VAULT_ALB_SUBNETS\)\(=\)\(.*\),\1\2${a_VAULT_ALB_SUBNETS},g;
               s,^\(VAULT_CONSUMER_AWS_PROFILE_1\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_AWS_PROFILE_1},g;
               s,^\(VAULT_CONSUMER_AWS_ACCOUNT_ID_1\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_AWS_ACCOUNT_ID_1},g;
               s,^\(VAULT_CONSUMER_NAMESPACE_1\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_NAMESPACE_1},g;
               s,^\(VAULT_CONSUMER_AWS_PROFILE_2\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_AWS_PROFILE_2},g;
               s,^\(VAULT_CONSUMER_AWS_ACCOUNT_ID_2\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_AWS_ACCOUNT_ID_2},g;
               s,^\(VAULT_CONSUMER_NAMESPACE_2\)\(=\)\(.*\),\1\2${a_VAULT_CONSUMER_NAMESPACE_2},g" \
           $input_file
fi

# Check all mandatory parameters and exit if not set
chmod +x $input_file
source $input_file
should_exit=0
echo
echo ++++++++++++++++++++++++++++++++++++++
#printf "|\tVARIABLE\t|\tVALUE\t|\n"
for var in "$@"
do
  if [ -z ${!var} ]
  then
      echo -e "\xE2\x9D\x8C $var is mandatory"
      should_exit=1
  else
    echo -e "\xE2\x9C\x94 $var = ${!var}"
  fi
done
echo +++++++++++++++++++++++++++++++++++++++
echo

if [[ should_exit -ne 1 ]]
then
  echo All values are set. Continuing deployment ....
  while true; do
    read -p "Are you sure you want to go ahead [y/n]:" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
else
  exit
fi