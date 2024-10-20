pipeline_role_arn=$(aws iam get-role --role-name PipelineRole --query "Role.Arn" --output text)
echo "Pipeline role: $pipeline_role_arn"

deployment_folder="/home/ec2-user/environment/deployment"

# Define variables
BASE_NAME="my-codepipeline-bucket-customer"
REGION="us-east-1"

# Generate a unique bucket name by appending the current timestamp
BUCKET_NAME="${BASE_NAME}-$(date +%s)"

# Step 1: Create the S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

# Step 2: Output the generated bucket name
echo "S3 bucket '$BUCKET_NAME' has been created."

# Use `sed` with '|' as the delimiter to update the customer pipeline config from template
customer_template_file="$deployment_folder/pipeline-customer-template.json"
customer_output_file="$deployment_folder/pipeline-customer.json"
sed -e "s|pipeline-role-arn|$pipeline_role_arn|g" \
    -e "s|s3-bucket|$BUCKET_NAME|g" \
    "$customer_template_file" > "$customer_output_file"

echo "Updated customer JSON saved to $customer_output_file"

# create pipeline
aws codepipeline create-pipeline --cli-input-json file://$customer_output_file --region us-east-1