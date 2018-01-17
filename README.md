# AWS Potions

Helper scripts to create potions for aws functionality

## Code Deploy Pipeline Setup and deployment of code revisions
Scripts relating to code deployments

### Setup users, iam profiles for code deploy
```bash
./scripts/code-deploy/01.setup-users-profiles-for-code-deploy.sh --profile <aws_profile> --iamuser <code-deploy-user>
```

### Setup load balancer, for code deployments
```bash
./scripts/code-deploy/02.setup-classic-loadbalancer.sh --profile <aws_profile> --elb-name <elb-name> --instance-name <ec2-instance-name-to-attach-to-elb>
```

### Setup load balancer, for code deployments
```bash
./scripts/code-deploy/03.create-deployment-group.sh --profile <aws_profile>
```

### Deploy a new application version via code deploy
```bash
./scripts/code-deploy/04.deploy-application.sh --profile <aws_profile> --app-name <app-name> --deploy-bucket <bucket-name> --version <version>
```
