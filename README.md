# Overview

This template leverages Terraform to create an autoscaling infrastructure on AWS for deploying containerized applications using EKS with Fargate.

# Infrastructure Overview

- **EKS with Fargate:** Managed Kubernetes service with serverless compute for containers.
- **ECR:** Elastic Container Registry for storing and managing Docker container images.
- **ALB:** Application Load Balancer for distributing incoming application traffic.
- **VPC:** For creating a virtual private cloud and private/public subnets.
- **RDS:** Relational Database Service for a managed relational database.
- **Secrets Manager:** For securely storing and managing secrets.
- **ElastiCache:** Managed redis for caching data in-memory to reduce latency.
- **S3:** For storing static assets and logs.
- **ACM:** For managing SSL/TLS certificates.
- **Route 53:** DNS records will be managed manually, and will point to the ALB.
- **IAM:** For managing access to AWS services and resources securely.

## Getting Started

Create a new repository from this template and clone it to your local machine.

Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

or run `./scripts/setup.sh` to install necissary dependencies.

## Customizing Infrastructure

1. Create an AWS Account and configure your AWS CLI with your IAM user credentials.
1. Create an S3 bucket for each environment to store the Terraform state.
1. Update the staging and produciton `envs/` `backend.tf` with your unique S3 bucket name.
1. Update the `envs/` `terraform.tfvars` with your own values for the variables. Including your `domain`, and list of `services` you will be deploying.
1. If you need another environment, copy the `envs/staging` directory and update the `backend.tf` and `terraform.tfvars` file with the new environment variables.

## Deploying and Updating Infrastructure

1. Navigate to the relevant environment directory in `envs/`
1. Run `terraform init` to initialize the Terraform configuration.
1. Run `terraform plan` to see the resources that will be created.
1. Run `terraform apply` to create the resources.

## Application Configuration

When creating new service or migrating an existing service to leverage this infrastructure, the application should be containerized and have the following config files:

- `Dockerfile` with steps to install dependencies and start the app server.
- `docker-compose.yml` to build and run the `Dockerfile` as well as the redis and other necessary containers for local development use.
- `entrypoint.sh` script to run database setup, migrations and yarn for local use.
- `deploy/k8s/app/deployment.yml` defines the deployment configuration for the Ruby on Rails application, specifying the Docker image to use, the desired number of replicas, and environmental configurations. It sets up the necessary details for deploying the application pods in EKS.
- `deploy/k8s/app/service.yml` specifies the service that exposes the Rails application pods to the internal Kubernetes network or to the internet, defining how the application can be accessed within the cluster or through an external endpoint.
- `deploy/k8s/app/hpa.yml` defines the Horizontal Pod Autoscaler (HPA) configuration, which automatically scales the number of pods in a deployment based on observed CPU utilization.
- `deploy/k8s/app/configmap.yml` contains non-sensitive configuration data in key-value pairs that can be used by Rails application pods, such as environment variables.
- `deploy/k8s/namespace/namespace.yml` defines the Kubernetes namespace for the application, which isolates the resources and objects created for the application from other applications in the cluster.
- `deploy/k8s/core/deployment.yml` defines the deployment configuration for the CoreDNS service, which provides DNS resolution for the Kubernetes cluster.
- `.github/workflows/deploy.yml` GitHub Actions workflow file that automates the deployment process, including building the Docker image, pushing it to ECR, running migrations, and deploying the application to EKS.
- Secrets will be stored in AWS Secrets Manager and injected as environment variables during deployment.

You can use the examples below, replacing `app` with your app name, adding your required environment variables and modifying the resources as needed:

`deploy/k8s/app/configmap.yml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: app
data:
    <put your env variables here>
```

`deploy/k8s/app/deployment.yml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: service
        image: ECR_IMAGE
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_HOST
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASS
        resources:
          limits:
            cpu: "2000m"
            memory: "8Gi"
          requests:
            cpu: "1000m"
            memory: "7500Mi"
```

`deploy/k8s/app/hpa.yml`
```yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 500Mi
```

`deploy/k8s/app/service.yml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
  namespace: app
  annotations:
    # Ensure the AWS Load Balancer Controller manages this service for an ALB
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    # service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip" # Uncomment this line if you are using NLB
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    # Specific annotation for Fargate to ensure IP-based targeting is used
    service.beta.kubernetes.io/aws-load-balancer-target-type: "ip"
spec:
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  selector:
    app: app
```

`deploy/k8s/core/deployment.yml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
spec:
  replicas: 2
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      containers:
      - name: coredns
        image: 602401143452.dkr.ecr.us-east-2.amazonaws.com/eks/coredns:v1.11.1-eksbuild.4
        ports:
        - containerPort: 53
          protocol: UDP
        - containerPort: 53
          protocol: TCP
        resources:
          requests:
            cpu: "256m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1024Mi"
        args: ["-conf", "/etc/coredns/Corefile"]
```

`deploy/k8s/namespace/namespace.yml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app
```

## Deployment Workflow

1. Github Actions will run rspec tests when git PR is opened.
1. PR can’t be merged until tests pass and x number of developers review and approve.
1. Github Actions will run rspec tests again once PR is merged.
1. It will then build the latest Dockerfile and push the image to ECS.
1. Then the latest migrations will be run on the database.
1. Finally the latest image on ECS will be deployed to EKS.

You can get started with the example Github Actions workflow below, replacing `app` with your app name:

`.github/workflows/deploy.yml`
```yaml
name: Deploy to EKS

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    name: Build Image, Push to ECR and Deploy to EKS
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Determine ECR Repository
        id: repo-name
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/app-2.0" ]]; then
            echo "::set-output name=REPOSITORY::staging-app-images"
          elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "::set-output name=REPOSITORY::production-app-images"
          fi

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: ${{ steps.repo-name.outputs.REPOSITORY }}
          IMAGE_TAG: latest
        run: |
          IMAGE_URI="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
          echo "Building image $IMAGE_URI"
          docker build -t $IMAGE_URI .
          echo "Pushing image $IMAGE_URI"
          docker push $IMAGE_URI
          echo "IMAGE=$IMAGE_URI" >> $GITHUB_ENV

      - name: Update kubeconfig
        run: aws eks --region us-east-2 update-kubeconfig --name staging-cluster

      - name: Deploy CoreDNS Configuration
        run: kubectl apply -f deploy/k8s/core/deployment.yml

      - name: Verify CoreDNS Deployment
        run: kubectl rollout status deployment/coredns -n kube-system

      - name: Deploy Namespace
        run: kubectl apply -f deploy/k8s/namespace/namespace.yml --v=6

      ## TODO: Abstract this based on environment being run/deployed
      - name: Retrieve Secrets from AWS Secrets Manager
        run: |
          echo "::add-mask::$(aws secretsmanager get-secret-value --secret-id staging-app-db-host --query 'SecretString' --output text)"
          DB_HOST=$(aws secretsmanager get-secret-value --secret-id staging-app-db-host --query 'SecretString' --output text)
          echo "DB_HOST=***" >> $GITHUB_ENV
          echo "::add-mask::$(aws secretsmanager get-secret-value --secret-id staging-app-db-pass --query 'SecretString' --output text)"
          DB_PASS=$(aws secretsmanager get-secret-value --secret-id staging-app-db-pass --query 'SecretString' --output text)
          echo "DB_PASS=***" >> $GITHUB_ENV

      - name: Create Kubernetes Secrets
        run: |
          kubectl create secret generic app-secrets \
          --from-literal=DB_HOST=${{ env.DB_HOST }} \
          --from-literal=DB_PASS=${{ env.DB_PASS }} \
          --namespace app \
          --dry-run=client -o yaml | kubectl apply -f -

      - name: Deploy ConfigMap
        run: kubectl apply -f deploy/k8s/app/configmap.yml --v=6

      # - name: Deploy HPA
      #   run: kubectl apply -f deploy/k8s/app/hpa.yml --v=6

      - name: Deploy to EKS
        run: |
          sed -i 's|ECR_IMAGE|${{ env.IMAGE }}|g' deploy/k8s/app/deployment.yml
          kubectl apply -f deploy/k8s/app/deployment.yml --v=6
          kubectl apply -f deploy/k8s/app/service.yml --v=6

      - name: Verify deployment
        run: kubectl rollout status deployment/app -n app --v=6
```

## Connecting to Database from Local Environment

Database connection are made through an EC2 Bastion host using AWS SSM Session Manager.

First install the AWS CLI and Session Manager Plugin:
```bash
brew install awscli session-manager-plugin
```

Configure the AWS CLI with your IAM user credentials and region:
```bash
aws configure
```

Start a port forwarding session to the Bastion host:
```bash
aws ssm start-session --target <instance-id-of-bastion-host> --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3307"], "localPortNumber":["3307"]}'
```

Connect to the database using the local forwarded port:
```bash
mysql -h 127.0.0.1 -P 3307 -u [your-username] -p
```

## Resources

### 1. Amazon EKS (Elastic Kubernetes Service)

EKS is a managed container service to run and scale Kubernetes applications in the cloud or on-premises. EKS manages the control plane for you (with high availability across zones), but you still have the flexibility to configure the compute layer.

- **AWS::EKS::Cluster**: For creating and managing an Amazon EKS cluster.
- **AWS::EKS::NodeGroup**: Optionally, for managing worker nodes directly managed by EKS. You can use this if you prefer EKS to manage the worker nodes instead of using Fargate.

### 2. AWS Fargate

Fargate is a serverless compute engine for containers that works with both Amazon ECS and EKS. With Fargate, you don't need to provision or manage servers; you specify the CPU and memory requirements for your containers, and Fargate manages the scaling and infrastructure for you.

- When using Fargate with EKS, you specify Fargate profiles directly in your EKS setup. The Fargate profiles allow you to specify which pods run on Fargate. This configuration is part of the EKS cluster setup and not a separate CloudFormation resource.

### 3. Amazon ECR (Elastic Container Registry)

To store, manage, and deploy Docker container images.

- **AWS::ECR::Repository**: To create Docker container registries for storing your application's container images.

### 4. AWS Application Load Balancer (ALB)

For distributing incoming application traffic across multiple targets, such as Docker containers, in multiple Availability Zones.

- **AWS::ElasticLoadBalancingV2::LoadBalancer**: To create an ALB.
- **AWS::ElasticLoadBalancingV2::TargetGroup**: For routing requests to one or more targets (managed by ECS or EKS/Fargate services).
- **AWS::ElasticLoadBalancingV2::Listener**: To define how the load balancer routes requests to its registered targets.

### 5. AWS CloudFront (Optional)

For a globally distributed content delivery network (CDN) service to deliver your application.

- **AWS::CloudFront::Distribution**: To create a CloudFront distribution for caching and delivering content for your application.

### 6. Amazon RDS

If your application requires a relational database, RDS is a managed relational database service.

- **AWS::RDS::DBInstance**: For creating and managing an RDS database instance.

### 7. AWS Secrets Manager

To securely store, manage, and retrieve secrets, such as database credentials or API keys.

- **AWS::SecretsManager::Secret**: For creating and managing secrets.

### 8. AWS CloudWatch

For monitoring your application and infrastructure performance with customizable metrics, logs, and alarms.

- **AWS::CloudWatch::Alarm**: To create alarms based on specific metrics for scaling or notifying.
- **AWS::Logs::LogGroup**: For storing logs from your containers and infrastructure.