# create codedeploy application
aws deploy create-application \
--application-name microservices \
--compute-platform ECS

# verify application running
aws deploy get-application --application-name microservices

customer_tg_two_arn=$(aws elbv2 describe-target-groups --names customer-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)
employee_tg_two_arn=$(aws elbv2 describe-target-groups --names employee-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)

deploy_role_arn=$(aws iam get-role --role-name DeployRole --query "Role.Arn" --output text)
echo "Deploy role: $deploy_role_arn"

lb_arn=$(aws elbv2 describe-load-balancers --names microservicesLB --query "LoadBalancers[0].LoadBalancerArn" --output text)
echo $lb_arn

listener_8080_arn=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --query "Listeners[?Port==\`8080\`].ListenerArn" --output text)
listener_80_arn=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --query "Listeners[?Port==\`80\`].ListenerArn" --output text)
echo "Listener 8080: $listener_8080_arn"
echo "Listener 80: $listener_80_arn"

# create codedeploy group for customer
aws deploy create-deployment-group \
--application-name microservices \
--deployment-group-name microservices-customer \
--service-role-arn $deploy_role_arn \
--deployment-config-name CodeDeployDefault.ECSAllAtOnce \
--ecs-services clusterName=microservices-serverlesscluster,serviceName=customer-microservice \
--load-balancer-info "targetGroupPairInfoList=[{targetGroups=[{name=customer-tg-two},{name=customer-tg-one}],prodTrafficRoute={listenerArns=[\"$listener_80_arn\"]},testTrafficRoute={listenerArns=[\"$listener_8080_arn\"]}}]" \
--deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
--blue-green-deployment-configuration "terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=5},deploymentReadyOption={actionOnTimeout=CONTINUE_DEPLOYMENT}"

# create codedeploy group for employee
aws deploy create-deployment-group \
--application-name microservices \
--deployment-group-name microservices-employee \
--service-role-arn $deploy_role_arn \
--deployment-config-name CodeDeployDefault.ECSAllAtOnce \
--ecs-services clusterName=microservices-serverlesscluster,serviceName=employee-microservice \
--load-balancer-info "targetGroupPairInfoList=[{targetGroups=[{name=employee-tg-two},{name=employee-tg-one}],prodTrafficRoute={listenerArns=[\"$listener_80_arn\"]},testTrafficRoute={listenerArns=[\"$listener_8080_arn\"]}}]" \
--deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
--blue-green-deployment-configuration "terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=5},deploymentReadyOption={actionOnTimeout=CONTINUE_DEPLOYMENT}"

