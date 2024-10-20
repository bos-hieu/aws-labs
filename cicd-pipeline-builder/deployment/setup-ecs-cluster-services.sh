customer_tg_two_arn=$(aws elbv2 describe-target-groups --names customer-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)
employee_tg_two_arn=$(aws elbv2 describe-target-groups --names employee-tg-two --query "TargetGroups[0].TargetGroupArn" --output text)
echo "target group: $customer_tg_two_arn $employee_tg_two_arn"

subnet1_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public Subnet1" --query "Subnets[0].SubnetId" --output text)
subnet2_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public Subnet2" --query "Subnets[0].SubnetId" --output text)
echo $subnet1_id $subnet2_id

security_group_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=microservices-sg" --query "SecurityGroups[0].GroupId" --output text)
echo $security_group_id

customer_revision_number=$(aws ecs describe-task-definition --task-definition customer-microservice --query "taskDefinition.revision" --output text)
employee_revision_number=$(aws ecs describe-task-definition --task-definition employee-microservice --query "taskDefinition.revision" --output text)
echo $customer_revision_number $employee_revision_number

# set deployment folder
deployment_folder="/home/ec2-user/environment/deployment"

# Use `sed` with '|' as the delimiter to update the customer service config from template
customer_template_file="$deployment_folder/create-customer-microservice-tg-two-template.json"
customer_output_file="$deployment_folder/create-customer-microservice-tg-two.json"
sed -e "s|REVISION-NUMBER|$customer_revision_number|g" \
    -e "s|PUBLIC-SUBNET-1-ID|$subnet1_id|g" \
    -e "s|PUBLIC-SUBNET-2-ID|$subnet2_id|g" \
    -e "s|SECURITY-GROUP-ID|$security_group_id|g" \
    -e "s|MICROSERVICE-TG-TWO-ARN|$customer_tg_two_arn|g" \
    "$customer_template_file" > "$customer_output_file"

echo "Updated customer JSON saved to $customer_output_file"

# Use `sed` with '|' as the delimiter to update the employee service config from template
employee_template_file="$deployment_folder/create-employee-microservice-tg-two-template.json"
employee_output_file="$deployment_folder/create-employee-microservice-tg-two.json"
sed -e "s|REVISION-NUMBER|$employee_revision_number|g" \
    -e "s|PUBLIC-SUBNET-1-ID|$subnet1_id|g" \
    -e "s|PUBLIC-SUBNET-2-ID|$subnet2_id|g" \
    -e "s|SECURITY-GROUP-ID|$security_group_id|g" \
    -e "s|MICROSERVICE-TG-TWO-ARN|$employee_tg_two_arn|g" \
    "$employee_template_file" > "$employee_output_file"

echo "Updated employee JSON saved to $employee_output_file"

# navigate to deployment folder
cd $deployment_folder

# create customer ecs service
aws ecs create-service --service-name customer-microservice --cli-input-json file://create-customer-microservice-tg-two.json

# create employee ecs service
aws ecs create-service --service-name employee-microservice --cli-input-json file://create-employee-microservice-tg-two.json
