#!/bin/bash
input_file=hvault-deploy/local-data/val.env
echo "$@"
while true
do
  status=`aws cloudformation describe-stacks --stack-name $1 --profile $4| jq --raw-output '.Stacks[].StackStatus'`
  case "$status" in
    REVIEW_IN_PROGRESS|ROLLBACK_IN_PROGRESS|DELETE_IN_PROGRESS|CREATE_IN_PROGRESS)
      echo "$status" ....
      sleep 20
      ;;
    CREATE_COMPLETE|DELETE_COMPLETE|CREATE_FAILED)
      echo $status
      jq_r=".Stacks[].Outputs[]| select(.OutputKey == \""$2"\").OutputValue"
      exp_val=`aws cloudformation describe-stacks --stack-name "$1" --profile "$4" | jq --raw-output "$jq_r"`
      val_to_replace="$3"
      if [[ ! -z "$val_to_replace" ]]
      then
        sed -i -e "s,^\(${val_to_replace}\)\(=\)\(.*\),\1\2${exp_val},g" $input_file
      fi
      break
      ;;
  esac
done