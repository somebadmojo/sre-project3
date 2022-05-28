#!/bin/bash

DEPLOY_INCREMENTS=2

# function manual_verification {
#   read -p "Continue deployment? (y/n) " answer
# 
#     if [[ $answer =~ ^[Yy]$ ]] ;
#     then
#         echo "continuing deployment"
#     else
#         exit
#     fi
# }

#Deployment Increments Math for 50%
#  If odd, an additional pod will be deployed to ensure there's sufficient resources to run 50% load.
#  For instance if there are 5 pods, half of 5 is 2.5, we would scale up 3 of the new pod, scale down 2 of the old

DEPLOYMENT_SIZE=$(kubectl get pods -n udacity | grep -c canary)
DEPLOYMENT_INCREMENT=$(((DEPLOYMENT_SIZE+1)/2))
DEPLOYMENT_DECREMENT=$(((DEPLOYMENT_SIZE)/2))


function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"


  kubectl scale deployment canary-v2 --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS))
  kubectl scale deployment canary-v1 --replicas=$((NUM_OF_V1_PODS - $DEPLOY_DECREMENTS))
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
}

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml

sleep 1
# Begin canary deployment
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -gt 0 ]
do
  canary_deploy
#  manual_verification
done

echo "Canary deployment of v2 successful"


