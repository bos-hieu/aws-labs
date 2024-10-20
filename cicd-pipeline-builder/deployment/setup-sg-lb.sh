vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=LabVPC" --query "Vpcs[*].VpcId" --output text)
echo $vpc_id

# create security group
aws ec2 create-security-group \
--group-name microservices-sg \
--description "Security group for microservices allowing HTTP and custom port" \
--vpc-id $vpc_id

# retrieve the security-group-id just created
security_group_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=microservices-sg" --query "SecurityGroups[0].GroupId" --output text)
echo $security_group_id

# Add inbound rules that allow TCP traffic from any IPv4 address on ports 80.
aws ec2 authorize-security-group-ingress \
--group-id $security_group_id \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0

# Add inbound rules that allow TCP traffic from any IPv4 address on ports 8080.
aws ec2 authorize-security-group-ingress \
--group-id $security_group_id \
--protocol tcp \
--port 8080 \
--cidr 0.0.0.0/0


# retrieve Ids of PublicSubnet1 and PublicSubnet2
subnet1_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public Subnet1" --query "Subnets[0].SubnetId" --output text)
subnet2_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public Subnet2" --query "Subnets[0].SubnetId" --output text)
echo $subnet1_id $subnet2_id

# create load-balancer 
aws elbv2 create-load-balancer \
--name microservicesLB \
--subnets $subnet1_id $subnet2_id \
--security-groups $security_group_id \
--scheme internet-facing \
--type application \
--ip-address-type ipv4

# waiting until load balancer available
echo "waiting until load balancer available"
aws elbv2 wait load-balancer-available --names microservicesLB

lb_arn=$(aws elbv2 describe-load-balancers --names microservicesLB --query "LoadBalancers[0].LoadBalancerArn" --output text)
echo $lb_arn

customer_tg_one_arn=$(aws elbv2 describe-target-groups --names customer-tg-one --query "TargetGroups[0].TargetGroupArn" --output text)
customer_tg_two_arn=$(aws elbv2 describe-target-groups --names customer-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)
echo "Customer targets: $customer_tg_one_arn $customer_tg_two_arn"


employee_tg_one_arn=$(aws elbv2 describe-target-groups --names employee-tg-one --query "TargetGroups[0].TargetGroupArn" --output text)
employee_tg_two_arn=$(aws elbv2 describe-target-groups --names employee-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)
echo "Employee targets: $employee_tg_one_arn $employee_tg_two_arn"

# Create the listener listens on HTTP:80 and forward traffic to customer-tg-two by default
aws elbv2 create-listener \
--load-balancer-arn $lb_arn \
--protocol HTTP \
--port 80 \
--default-actions Type=forward,TargetGroupArn=$customer_tg_two_arn

# # Create the listener listens on HTTP:8080 and forward traffic to customer-tg-one by default.
aws elbv2 create-listener \
--load-balancer-arn $lb_arn \
--protocol HTTP \
--port 8080 \
--default-actions Type=forward,TargetGroupArn=$customer_tg_one_arn

listener_8080_arn=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --query "Listeners[?Port==\`8080\`].ListenerArn" --output text)
listener_80_arn=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn --query "Listeners[?Port==\`80\`].ListenerArn" --output text)
echo $listener_8080_arn $listener_80_arn

# Add a second rule for the HTTP:80 listener. Define the following logic for this new rule:
# - IF Path is /admin/* 
# - THEN Forward to... the employee-tg-two target group.
aws elbv2 create-rule \
--listener-arn $listener_80_arn \
--conditions Field=path-pattern,Values=/admin/* \
--priority 1 \
--actions Type=forward,TargetGroupArn=$employee_tg_two_arn

# Add a second rule for the HTTP:8080 listener. Define the following logic for this new rule:
# IF Path is /admin/* 
# THEN Forward to the employee-tg-one target group.
aws elbv2 create-rule \
--listener-arn $listener_8080_arn \
--conditions Field=path-pattern,Values=/admin/* \
--priority 1 \
--actions Type=forward,TargetGroupArn=$employee_tg_one_arn
