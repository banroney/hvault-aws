#!/bin/bash
input_file=hvault-deploy/local-data/val.env
profile=$1
stack=$2
shift 2
while true
do
  raw_json=`aws cloudformation describe-stacks --stack-name $stack --profile $profile`
  status=`echo $raw_json | jq --raw-output '.Stacks[].StackStatus'`
  case "$status" in
    REVIEW_IN_PROGRESS|ROLLBACK_IN_PROGRESS|DELETE_IN_PROGRESS|CREATE_IN_PROGRESS)
      echo "$status" ....
      sleep 20
      ;;
    CREATE_COMPLETE)
      echo $status
      for var in "$@"
      do
        val_key=`echo $var | cut -d ':' -f1`
        val_rep=`echo $var | cut -d ':' -f2`

        jq_r=".Stacks[].Outputs[]| select(.OutputKey == \""$val_key"\").OutputValue"
        exp_val=`echo $raw_json| jq --raw-output "$jq_r"`

        if [[ ! -z "$val_rep" ]]
        then
          echo Substituting for $val_rep with $exp_val
          sed -i -e "s,^\(${val_rep}\)\(=\)\(.*\),\1\2${exp_val},g" $input_file
        fi
      done
      break
      ;;
    *)
      echo $status
      echo "Exiting"
      break
      ;;
  esac
done