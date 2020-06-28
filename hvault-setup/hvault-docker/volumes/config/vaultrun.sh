#!/bin/sh
while :
do
	echo "Wating for vault to get started.."
	v_init=`curl $VAULT_ADDR/v1/sys/seal-status|jq ".initialized"`
  echo $v_init
	sleep 10
done
