#!/bin/bash


function canary_deploy {

  kubectl scale deployment canary-v2 --replicas=$(($DEPLOY_TARGET_SIZE))
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary v2 deployment of $DEPLOY_TARGET_SIZE replicas successful!"
  # scale down after successful deployment of v2
  kubectl scale deployment canary-v1 --replicas=$(($DEPLOY_TARGET_SIZE))
}


function green_deploy {
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/green -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Green deployment successful"
}

kubectl apply -f green.yml

sleep 1
# Begin canary deployment
  green_deploy
 
