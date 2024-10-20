# Create microservices codecommit repository
aws codecommit create-repository --repository-name microservices --repository-description "microservices repository"

# Create customer ecr
aws ecr create-repository --repository-name customer
aws ecr set-repository-policy \
--repository-name customer \
--policy-text '{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "ecr:*"
        }
    ]
}'

# Create employee ecr
aws ecr create-repository --repository-name employee
aws ecr set-repository-policy \
--repository-name employee \
--policy-text '{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "ecr:*"
        }
    ]
}'


# Build docker images
# Must be in the directory that has the Dockerfile before you attempt to build a new image
cd ~/environment/microservices/customer

# Build a new image from the latest source files and overwrite any existing image
docker build --tag customer .

# Must be in the directory that has the Dockerfile before you attempt to build a new image
cd ~/environment/microservices/employee

# Build a new image from the latest source files and overwrite any existing image
docker build --tag employee .


# Get account id
account_id=$(aws sts get-caller-identity |grep Account|cut -d '"' -f4)
echo $account_id

# authorize your Docker client to connect to the Amazon ECR service
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $account_id.dkr.ecr.us-east-1.amazonaws.com

# Tag the customer image
docker tag customer:latest $account_id.dkr.ecr.us-east-1.amazonaws.com/customer:latest

# Tag the employee image
docker tag employee:latest $account_id.dkr.ecr.us-east-1.amazonaws.com/employee:latest

# Push customer image to ecr
docker push $account_id.dkr.ecr.us-east-1.amazonaws.com/customer:latest

# Push employee image to ecr
docker push $account_id.dkr.ecr.us-east-1.amazonaws.com/employee:latest

# push code to codecommit
cd ~/environment/microservices

# remove the current git config
rm -rf .git/
git init
git branch -m dev 
git add .
git commit -m 'add latest code to code commit'
git remote add origin https://git-codecommit.us-east-1.amazonaws.com/v1/repos/microservices
git push -u origin dev