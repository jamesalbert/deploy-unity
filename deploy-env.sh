#!/usr/bin/env bash

set -e

function get-config {
  jq -r .$1 config.json
}

function get-aws-config {
  aws configure get $1
}

function get-sts-config {
  aws sts get-caller-identity | jq -r .$1
}

function ecr-login {
  eval `aws ecr get-login --no-include-email --region $REGION`
}

function build {
  docker build --no-cache --build-arg BUILD_DIR=$BUILD_DIR -t $NAME .
}

function push {
  ecs-cli push $NAME:$TAG
}

function new-container {
  cp templates/container-template.json container.json
  sed -i '' s/\<NAME\>/${NAME}/g container.json
  sed -i '' s/\<REGION\>/${REGION}/g container.json
  sed -i '' s/\<REPO_URL\>/${REPO_URL}/g container.json
  sed -i '' s/\<MEMORY\>/${MEMORY}/g container.json
}

function revise {
  echo "creating new task definition revision..."
  new-container
  aws ecs register-task-definition \
    --family $NAME \
    --task-role-arn $TASK_ROLE_ARN \
    --execution-role-arn $EXECUTION_ROLE_ARN \
    # --network-mode $NETWORK_MODE \
    --cpu $CPU \
    --memory $MEMORY \
    --requires-compatibilities EC2 \
    --cli-input-json file://$PWD/container.json > container-out.json
  export REVISION=`jq .taskDefinition.revision container-out.json`
}

function update {
  echo "updating service..."
  aws ecs update-service \
    --cluster $CLUSTER \
    --service $NAME \
    --task-definition $NAME:$REVISION > service-out.json
}

function deploy {
  ecr-login
  build
  push
  revise
  update
  echo "DEPLOYMENT SUCCESSFUL"
}

function deactivate {
  exec $SHELL -l
}

# TODO: add defaults
function reload-config {
  export BUILD_DIR=`get-config build_dir`
  export NAME=`get-config name`
  export TAG=`get-config tag`
  export PRIVATE_KEY_PATH=`get-config private_key`
  export INSTANCE_COUNT=`get-config instance_count`
  export INSTANCE_TYPE=`get-config instance_type`
  export TASK_ROLE_ARN=`get-config task_role_arn`
  export EXECUTION_ROLE_ARN=`get-config execution_role_arn`
  export NETWORK_MODE=`get-config network_mode`
  export CPU=`get-config cpu`
  export MEMORY=`get-config memory`
  export CLUSTER=`get-config cluster`
  export REGION=`get-aws-config region`
  export ID=`get-sts-config Account`
  export REPO_URL="$ID.dkr.ecr.$REGION.amazonaws.com\/$NAME:$TAG"
}

export PS1="(deploy-env) $PS1"
reload-config
