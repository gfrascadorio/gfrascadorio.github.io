#!/bin/bash

##
# aws_sudo 
#   Execute a shell command in the context of the specified aws role
#
# USAGE
#   aws_sudo role command
#
# EXAMPLE
#   aws_sudo arn:aws:iam::40nnnnnnnnn4:role/{assumable role} {command}
#   aws_sudo arn:aws:iam::40nnnnnnnnn4:role/SomeRole aws s3 ls appxxxbucket

if [ $# -lt 2 ]; then
    echo 'usage: aws_sudo arn:aws:iam::40nnnnnnnnn4:role/{assumable role} {command}'
    exit 1
fi

role="$1"
session=$(echo "$role" | egrep -o '\w+$')
shift 1

json=$(aws sts assume-role --role-arn "$role" --role-session-name "$session")

ACCESS_KEY=$(echo "$json" | jq  '.Credentials.AccessKeyId' --raw-output)
SECRET_KEY=$(echo "$json" | jq  '.Credentials.SecretAccessKey' --raw-output)
SESSION_TOKEN=$(echo "$json" | jq  '.Credentials.SessionToken' --raw-output)

AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} AWS_SESSION_TOKEN=${SESSION_TOKEN} bash -c "$*"

