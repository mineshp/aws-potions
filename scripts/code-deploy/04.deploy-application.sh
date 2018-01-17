export AWS_DEFAULT_REGION=eu-west-1

PROJECTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..
PARAMETERS_FILE="/tmp/prodman-deploy-image-resizing-bluegreen-deploy-params.json"
PROFILE=""
APP_NAME=""
DEPLOY_BUCKET=""
VERSION=""

usage() {
  echo "--profile is required"
  echo "--app-name is required"
  echo "--deploy-bucket is required"
  echo "--version is required"
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
      -n|--app-name)
      APP_NAME="$2"
      shift
    ;;
      -b|--deploy-bucket)
      DEPLOY_BUCKET="$2"
      shift
    ;;
      -v|--version)
      VERSION="$2"
      shift
    ;;
  esac
  shift
done

if [ -z "$PROFILE" ]; then
  echo 'profile missing';
  usage 4
fi

if [ -z "$APP_NAME" ]; then
  echo 'app name missing';
  usage 4
fi

if [ -z "$DEPLOY_BUCKET" ]; then
  echo 'bucket missing';
  usage 4
fi

if [ -z "$VERSION" ]; then
  echo 'version missing';
  usage 4
fi


CODE_DEPLOY_APPLICATION_NAME=$APP_NAME
DEPLOYMENT_GROUP_NAME=$APP_NAME-deployments

DEPLOYMENT_TYPE="CodeDeployDefault.OneAtATime"

APP_NAME=$APP_NAME-app

# Do the actual deploy using code deploy
DEPLOYMENT=$(aws --profile $PROFILE deploy create-deployment \
  --application-name $CODE_DEPLOY_APPLICATION_NAME \
  --deployment-config-name $DEPLOYMENT_TYPE \
  --deployment-group-name $DEPLOYMENT_GROUP_NAME  \
  --description "Code deploy the Morpheus application version $VERSION one at a time" \
  --s3-location bucket=$DEPLOY_BUCKET,bundleType=zip,key=deployments/$APP_NAME-$VERSION.zip)

echo "Code deploy to fleet ${DEPLOYMENT_GROUP_NAME} has started."

# Get deployment id, to check status later
DEPLOYMENT_ID=$( echo $DEPLOYMENT | jq -r '.deploymentId')

CHECK_DEPLOYMENT_STATUS=""
PROGRESS=""
echo "Checking for code deployment status:"

while [ "$CHECK_DEPLOYMENT_STATUS" != "Succeeded" ]; do
  CHECK_DEPLOYMENT_STATUS=$(aws --profile $PROFILE deploy get-deployment --deployment-id $DEPLOYMENT_ID | jq -r '.deploymentInfo | .status')

  if [ "$CHECK_DEPLOYMENT_STATUS" != "$PROGRESS" ]; then
    PROGRESS=$CHECK_DEPLOYMENT_STATUS
    echo $PROGRESS
  fi

  if [ "$CHECK_DEPLOYMENT_STATUS" = "Failed" ]; then
    echo "Deployment failed, please see code deploy in console for error"
    break
  fi
  sleep 3
done

if [ "$CHECK_DEPLOYMENT_STATUS" = "Succeeded" ]; then
  echo "Code deploy to fleet ${DEPLOYMENT_GROUP_NAME} successfully completed"
else
  echo "Unable to deploy new application, no healthy instances available"
fi