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
    source $input_file
else
    echo Input File doesnt exist. Creating input file "$input_file". Please fill it up
    mkdir -p `dirname "$input_file"` && cp $input_template $input_file
    chmod +x $input_file
    exit
fi

# Check all mandatory parameters and exit if not set

should_exit=0
echo
echo ++++++++++++++++++++++++++++++++++++++
#printf "|\tVARIABLE\t|\tVALUE\t|\n"
for var in "$@"
do
  if [ -z ${!var} ]
  then
      #printf "|\t%s\t|\t%s\t|\n" "'\xE2\x9D\x8C' $var" "EMPTY"
      echo -e "\xE2\x9D\x8C $var is mandatory"
      should_exit=1
  else
    #printf "|\t%s\t|\t%s\t|\n" "'\xE2\x9C\x94' $var" "${!var}"
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