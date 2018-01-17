#!/bin/sh

PROFILE=""
PROJECTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..
LOAD_BALANCER_NAME=""
EC2_INSTANCE_NAME=''
# PARAMETERS_FILE="/tmp/create-deployment-pipeline.json"

usage() {
  echo "--profile is required"
  echo "--elb-name is required"
  echo "--instance-name is required"
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
    -l|--elb-name)
      LOAD_BALANCER_NAME="$2"
      shift
    ;;
    -i|--instance-name)
      EC2_INSTANCE_NAME="$2"
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

if [ -z "$LOAD_BALANCER_NAME" ]; then
  usage 4
fi

if [ -z "$EC2_INSTANCE_NAME" ]; then
  usage 4
fi

SUBNETS=$(aws --profile $PROFILE ec2 describe-subnets | jq -r '.Subnets[] | .SubnetId')
DEFAULT_SECURITY_GROUP=$(aws --profile $PROFILE ec2 describe-security-groups)
DEFAULT_SECURITY_GROUP_ID=$(echo $DEFAULT_SECURITY_GROUP | jq -r '.SecurityGroups[] | select(.GroupName == "default") | .GroupId')
DEFAULT_VPC_ID=$(echo $DEFAULT_SECURITY_GROUP | jq -r '.SecurityGroups[] | select(.GroupName == "default") | .VpcId')
echo $DEFAULT_SECURITY_GROUP_ID

LOAD_BALANCER_ARN=$(aws --profile $PROFILE elbv2 create-load-balancer --name $LOAD_BALANCER_NAME --subnets $SUBNETS --security-groups $DEFAULT_SECURITY_GROUP_ID | jq -r '.LoadBalancers[].LoadBalancerArn')
echo "LOAD BALANCER ARN is $LOAD_BALANCER_ARN"

TARGET_GROUP_ARN=$(aws --profile $PROFILE elbv2 create-target-group --name my-target-groups --protocol HTTP --port 80 --vpc-id $DEFAULT_VPC_ID | jq -r '.TargetGroups[].TargetGroupArn')
echo "TARGET_GROUP_ARN is $TARGET_GROUP_ARN"

EC2_MORPHEUS_INSTANCE_ID=$(aws --profile $PROFILE ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value=="'"$EC2_INSTANCE_NAME"'") | .InstanceId')
echo "MORPHEUS INSTANCE ID $EC2_MORPHEUS_INSTANCE_ID"

REGISTER_TARGETS=$(aws --profile $PROFILE elbv2 register-targets --target-group-arn $TARGET_GROUP_ARN --targets Id=$EC2_MORPHEUS_INSTANCE_ID)
echo "REGISTER TARGETS $REGISTER_TARGETS"

CREATE_LISTENER=$(aws --profile $PROFILE elbv2 create-listener --load-balancer-arn $LOAD_BALANCER_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN)
echo "CREATE LISTENER $CREATE_LISTENER"

echo "LOAD BALANCER created and ec2 instance $EC2_INSTANCE_NAME attached"