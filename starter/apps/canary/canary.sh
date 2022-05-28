#!/bin/bash

#Deployment Increments Math for 50%
#  If odd, an additional pod will be deployed to ensure there's sufficient resources to run 50% load as we can't deploy half a pod.
#  ie. If there are 5 pods, half of 5 is 2.5, we would scale up 3 of the new pod, scale down 2 of the old

DEPLOYMENT_SIZE=$(kubectl get pods -n udacity | grep -c canary)
#  bash cli math evaluation always rounds down.  5/2 = 2
#  we want it to round up so we add +1 to DEPLOYMENT_SIZE
DEPLOY_TARGET_SIZE=$(((DEPLOYMENT_SIZE+1)/2))


function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c "canary-v1.*Running")
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c "canary-v2.*Running")
  echo "V2 PODS: $NUM_OF_V2_PODS"


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

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml

sleep 1
# Begin canary deployment
  canary_deploy

echo "50% deployment of canary-v2 successful"
