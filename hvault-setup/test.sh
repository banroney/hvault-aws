#!/bin/bash

while read -r line; do
  if [[ $line =~ ^([a-zA-Z0-9_])=(.*)$  ]]; then
    echo "$line"
  fi
done < ./hvault-setup/template_vals.env