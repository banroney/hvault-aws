#!/bin/bash

usage="$(basename "$0") [-h] [-d n][-s n] -- program to deploy vault lambda or configure vault server

where:
    -h  show this help text
    -d  deploy options, available options are svc auth secret config
    -s  check status for stack, provide stack name"
input_file=./hvault-deploy/local-data/val.env

while getopts ':hd:s:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    d) part=$OPTARG
       case "$part" in
        svc|secret) echo "Deploying Hashicorp $part in AWS ..."
             source hvault-deploy/hvault_"$part"_deploy.sh "$@"
             ;;
        auth|config) echo "Deploying Hashicorp $part in AWS ..."
             source $input_file
             echo $VAULT_CONSUMER_AWS_ACCOUNT_ID_1
             if [[ ! -z "$VAULT_CONSUMER_AWS_ACCOUNT_ID_1" ]]
             then
               echo here now
               source hvault-deploy/hvault_"$part"_deploy.sh 1
             fi
             if [[ ! -z "$VAULT_CONSUMER_AWS_ACCOUNT_ID_2" ]]
             then
               source hvault-deploy/hvault_"$part"_deploy.sh 2
             fi
             ;;
        all) echo deploy all
             source hvault-deploy/hvault_svc_deploy.sh
             source hvault-deploy/hvault-stack-status.sh default hvault-svc\
                                                         HVaultECSEndpoint:VAULT_SERVICE_URL \
                                                         HVaultOption3RoleConsumer1:VAULT_CONSUMER_ROLE_ARN_1 \
                                                         HVaultOption3RoleConsumer2:VAULT_CONSUMER_ROLE_ARN_2 \
                                                         HVaultRootToken:VAULT_SERVICE_TOKEN_SECRET_ARN
             source $input_file
             if [[ ! -z "$VAULT_CONSUMER_AWS_ACCOUNT_ID_1" ]]
             then
              source hvault-deploy/hvault_auth_deploy.sh 1
              source hvault-deploy/hvault-stack-status.sh $VAULT_CONSUMER_AWS_PROFILE_1 hvault-auth \
                                                         HVaultAccessFunctionIamRole:VAULT_OPT1_CONSUMER_ROLE_ARN_1
              source hvault-deploy/hvault_config_deploy.sh 1
             fi
             if [[ ! -z "$VAULT_CONSUMER_AWS_ACCOUNT_ID_2" ]]
             then
              source hvault-deploy/hvault_auth_deploy.sh 2
              source hvault-deploy/hvault-stack-status.sh $VAULT_CONSUMER_AWS_PROFILE_2 hvault-auth \
                                                         HVaultAccessFunctionIamRole:VAULT_OPT1_CONSUMER_ROLE_ARN_2
              source hvault-deploy/hvault_config_deploy.sh 2
             fi
             ;;
        *) printf "illegal option: -d %s\n" "$part" >&2
            echo "$usage" >&2
            exit 1
            ;;
       esac
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
    s) stack=$OPTARG
       shift 2
       source hvault-deploy/hvault-stack-status.sh $stack "$@"
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))