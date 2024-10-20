# Create deployment repository
aws codecommit create-repository --repository-name deployment --repository-description "deployment repository for microservices"

# Init the deployment folder
cd ~/environment/deployment

rm -rf .git/
git init
git branch -m dev 
git add .
git commit -m 'add latest code to code commit'
git remote add origin https://git-codecommit.us-east-1.amazonaws.com/v1/repos/deployment
git push -u origin dev

# update the taskdef-customer.json based on the template then create customer task definition
aws ecs register-task-definition --cli-input-json "file:///home/ec2-user/environment/deployment/taskdef-customer.json"

# update the taskdef-employee.json based on the template then create employee task definition
aws ecs register-task-definition --cli-input-json "file:///home/ec2-user/environment/deployment/taskdef-employee.json"
