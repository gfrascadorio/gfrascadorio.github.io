#!/bin/bash

##
# aws_runas
#   Execute a shell command in the context of the specified aws role
#   (see also aws_sudo.sh, but it requires 'jq')
#
# USAGE
#   aws_runas.sh role command
#
# EXAMPLE
#   aws_runas arn:aws:iam::40nnnnnnnnn4:role/{assumable role} {command}
#   aws_runas arn:aws:iam::40nnnnnnnnn4:role/AppxxxAuditorRoleVx aws s3 ls appxxxbucket

if [ $# -lt 2 ]; then
    echo 'usage: aws_runas arn:aws:iam::123456789012:role/{assumable role} {command}'
    echo '       aws_runas arn:aws:iam::123456789012:role/{assumable role} aws s3 ls {s3bucket}'
    exit 1
fi

role="$1"
session=$(echo "$role" | egrep -o '\w+$')
shift 1

json=$(aws sts assume-role --role-arn "$role" --role-session-name "$session")

ACCESS_KEY=$(echo "$json" | grep  'AccessKeyId' | sed 's/^.*: "\(.*\)".*$/\1/')
SECRET_KEY=$(echo "$json" | grep  'SecretAccessKey' | sed 's/^.*: "\(.*\)".*$/\1/')
SESSION_TOKEN=$(echo "$json" | grep  'SessionToken' | sed 's/^.*: "\(.*\)".*$/\1/')

echo $ACCESS_KEY
echo $SECRET_KEY
echo $SESSION_TOKEN

AWS_ACCESS_KEY_ID=${ACCESS_KEY} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} AWS_SESSION_TOKEN=${SESSION_TOKEN} bash -c "$*"

