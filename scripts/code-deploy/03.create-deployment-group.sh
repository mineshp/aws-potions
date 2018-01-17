#!/bin/sh

PROFILE=""
PROJECTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..
APP_NAME=""
# PARAMETERS_FILE="/tmp/create-deployment-pipeline.json"

usage() {
  echo "--profile is required"
  echo "--app-name is required"
  exit $1
}

while [[ $# > 0 ]]
do
  key="$1"

  case $key in
    -p|--profile)
      PROFILE="$2"
      shift
    ;;
    -a|--app-name)
      APP_NAME="$2"
      shift
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

if [ -z "$PROFILE" ]; then
  usage 4
fi

if [ -z "$APP_NAME" ]; then
  usage 4
fi

SERVICE_ROLE_ARN=$(aws --profile $PROFILE iam list-roles | jq -r '.Roles[] | select(.RoleName=="CodeDeployServiceRole") | .Arn')
echo $SERVICE_ROLE_ARN
aws --profile $PROFILE deploy create-deployment-group --application-name $APP_NAME --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name $APP_NAME-deployments --ec2-tag-filters Key=Name,Value=$APP_NAME,Type=KEY_AND_VALUE --service-role-arn $SERVICE_ROLE_ARN