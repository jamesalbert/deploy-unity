# deploy-unity

![](https://d2908q01vomqb2.cloudfront.net/cb4e5208b4cd87268b208e49452ed6e89a68e0b8/2018/02/28/Unity.jpg)

Deploy your Unity WebGL game to Amazon's Elastic Container Service using this handy-dandy virtual environment.


## How to Deploy Unity Builds


### Dependencies

  - aws-cli
  - ecs-cli
  - jq


### Things you need:

  - a domain ([guide](https://aws.amazon.com/getting-started/tutorials/get-a-domain/))
  - a TLS certificate ([guide](https://aws.amazon.com/blogs/aws/new-aws-certificate-manager-deploy-ssltls-based-apps-on-aws/))
  - an ECS cluster ([guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create_cluster.html)) and service ([guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-service.html))
    - name your service with the name you will set in `config.json`
    - recommended: set your service behind an ALB ([guide](https://aws.amazon.com/blogs/compute/microservice-delivery-with-amazon-ecs-and-application-load-balancers/))

To summarize, use your domain to create a CNAME to the ALB. Use the TLS certificate to encrypt the traffic between the client and the ALB. Then configure a target group to forward traffic to your service's tasks. This tool doesn't touch on any of these things, but you should have this setup before hosting a game. If this sounds unfamiliar to you, use da googles.

Last thing to note is to ensure that the ecs task role you use have ecr:* and logs:* permissions. It doesn't have to be *that* open, but  ¯\\\_(ツ)\_/¯.

### Configuration

Before you begin, be sure to have aws-cli and ecs-cli configured. If you don't already, follow this [guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for aws-cli, and this [guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_Configuration.html) for ecs-cli.

Once that's done, the first thing you need to do is fill out `config.json`:

  - name: the name for your ECR repository, task definition, and service
  - tag: tag your deploy (usually "latest")
  - cluster: name of your cluster
  - task_role_arn: role arn the containers will assume
  - execution_role_arn: role arn that container agents and docker daemon will assume
  - network_mode: bridge, host, awsvpc, or none
  - cpu: CPU units
  - memory: MiB units


### Deploying

Reminder: you must have a cluster and service ready before deployment.

If you're ready to go, here are the steps:
  - In Unity:
    - click File>Build Settings...
    - click WebGL
    - configure your build
    - click Build and choose this repo as the destination
  - Here:
    - run `. deploy_env.sh`
    - run `deploy`
    - when done, run `deactivate`

`deploy` will:
  - login to ECR
  - build the docker image (./Dockerfile)
  - push the image to ECR
  - create a new task definition revision
  - update the service with the new task definiton

While in the deploy environment, you can:
  - `ecr-login`: login to ECR
  - `build`: build the local docker image
  - `push`: push image (takes name from `config.json`.name) to ECR
  - `revise`: create new task definition revision
  - `update`: update the service with the new task definition
  - `deactivate`: deactivate deploy environment

That's the basic flow of things. You can always version control your builds and use this in something like Jenkins.
