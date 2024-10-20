# Create target groups
# set vpc id from console
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=LabVPC" --query "Vpcs[*].VpcId" --output text)
echo $vpc_id

# create customer-tg-one
aws elbv2 create-target-group \
--name customer-tg-one \
--protocol HTTP \
--port 8080 \
--vpc-id $vpc_id \
--target-type ip \
--health-check-path / \
--health-check-protocol HTTP

# create customer-tg-two
aws elbv2 create-target-group \
--name customer-tg-two \
--protocol HTTP \
--port 8080 \
--vpc-id $vpc_id \
--target-type ip \
--health-check-path / \
--health-check-protocol HTTP

# create employee-tg-one
aws elbv2 create-target-group \
--name employee-tg-one \
--protocol HTTP \
--port 8080 \
--vpc-id $vpc_id \
--target-type ip \
--health-check-path /admin/suppliers \
--health-check-protocol HTTP

# create employee-tg-two
aws elbv2 create-target-group \
--name employee-tg-two \
--protocol HTTP \
--port 8080 \
--vpc-id $vpc_id \
--target-type ip \
--health-check-path /admin/suppliers \
--health-check-protocol HTTP