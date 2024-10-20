# Task 5.2
- Create an ECS cluster with name: microservices-serverlesscluster
- Create a service in cluster with network setting is: LabVPC, PublicSubnet1, and PublicSubnet2 (remove any other subnets).

# How to set up
1. Create the cloud9 environment
2. Provisioning the microservices by `sh microservices/setup.sh`
3. Create ecs cluster
4. Setup deployment by `sh deployment/setup.sh`
5. Setup target groups: `sh deployment/setup-target-groups.sh`
6. Setup security groups and loadBalancers: `sh deployment/setup-sg-lb.sh`
7. Setup ecs cluster services: `sh deployment/setup-ecs-cluster-services.sh`
8. Setup codedeploy: