#!/bin/sh

IAM_DEPLOY_USER=""
PROFILE=""
PROJECTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..
PARAMETERS_FILE="/tmp/create-deployment-pipeline.json"

usage() {
  echo "--profile is required"
  echo "--iamuser is required"
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
    -u|--iamuser)
      IAM_DEPLOY_USER="$2"
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

if [ -z "$IAM_DEPLOY_USER" ]; then
  usage 4
fi


# # 1. Setup an IAM User

# -- Check if iam user already exists
IAM_DEPLOY_USER_ARN=$(aws --profile $PROFILE iam get-user --user-name $IAM_DEPLOY_USER | jq -r .User.Arn)

if [ "$IAM_DEPLOY_USER_ARN" ]; then
    echo "USER $IAM_DEPLOY_USER already exists, arn is $IAM_DEPLOY_USER_ARN"
else
    echo "USER $IAM_DEPLOY_USER not found, creating user."
    IAM_DEPLOY_USER_ARN=$(aws --profile $PROFILE iam create-user --user-name $IAM_DEPLOY_USER | jq -r .User.Arn)
fi

# # 2. Create a service Role for AWS Code Deploy
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CODE_DEPLOY_POLICY_ARN=$(aws --profile $PROFILE iam create-policy --policy-name code-deploy-policy --policy-document file://$DIR/../../resources/code-deploy/code-deploy-policy.json | jq -r .Policy.Arn)

aws --profile $PROFILE iam attach-user-policy --policy-arn $CODE_DEPLOY_POLICY_ARN --user-name $IAM_DEPLOY_USER

# 3. Create an IAM Instance Profile
SERVICE_ROLE_ARN=$(aws --profile $PROFILE iam create-role --role-name CodeDeployServiceRole --assume-role-policy-document file://$DIR/../../resources/code-deploy/code-deploy-service-role.json | jq -r .Role.Arn)
aws --profile $PROFILE iam attach-role-policy --role-name CodeDeployServiceRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

aws --profile $PROFILE iam create-role --role-name CodeDeploy-EC2-Instance-Profile --assume-role-policy-document file://$DIR/../../resources/code-deploy/code-deploy-ec2-trust.json
aws --profile $PROFILE iam put-role-policy --role-name CodeDeploy-EC2-Instance-Profile --policy-name CodeDeploy-EC2-Permissions --policy-document file://$DIR/../../resources/code-deploy/code-deploy-ec2-permissions.json

aws --profile $PROFILE iam create-instance-profile --instance-profile-name CodeDeploy-EC2-Instance-Profile
aws --profile $PROFILE iam add-role-to-instance-profile --instance-profile-name CodeDeploy-EC2-Instance-Profile --role-name CodeDeploy-EC2-Instance-Profile
echo "Ready for code deploy pipeline to be setup"