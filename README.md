# fleet-management-system

## About the Project

Fleet Management System is a live vehicle-tracking application for a transport company. Imagine a company that runs delivery trucks (lorries) all over the country — this system tracks where each vehicle is, in real time, as it moves around making deliveries.

The idea is simple:

- Each vehicle has a GPS device.
- Every few seconds the vehicle reports its position (latitude and longitude) back to a central server.
- The system stores that data, works out things like the vehicle's speed, and shows everything live on a map in the browser.

![Fleet Management System overview — vehicles reporting their positions to a central server](docs/images/fleet-overview.png)

Since there are no real trucks in this demo, the vehicle movement is simulated by one of the services (the Position Simulator), which replays real GPS tracks from data files.

The whole thing is built as a microservices architecture (instead of one big monolith — see [Concepts & Design Decisions](#concepts--design-decisions) below), packaged into Docker containers, and deployed on Kubernetes (AWS EKS).

## How It Works (High Level)

```
Position Simulator  ──>  Queue (ActiveMQ)  ──>  Position Tracker  ──>  MongoDB
                                                      │
                                                      ▼
                          API Gateway  ──>  Webapp (browser map)
```

#### The 5 Microservices

| Service | Tech |
|---------|------|
| **Position Simulator** | Java / Spring Boot |
| **Queue** | ActiveMQ |
| **Position Tracker** | Spring Boot + MongoDB |
| **API Gateway** | Spring Boot + Feign + Hystrix |
| **Webapp** | Angular 6 + Leaflet + nginx |

1. The Position Simulator pretends to be the moving vehicles and keeps sending their positions to a queue.
2. The Queue (ActiveMQ) holds those position messages so services stay decoupled.
3. The Position Tracker reads messages off the queue, calculates speed, stores history in MongoDB, and exposes a REST API.
4. The API Gateway is the single entry point the frontend talks to; it forwards requests to the right backend service.
5. The Webapp (Angular) shows the vehicles moving live on a map, with a list and route history.

---

# How Each Part Works

![Fleet Management System architecture — browser to nginx reverse proxy to API Gateway, with Position Simulator, ActiveMQ, and Position Tracker](docs/images/architecture.png)

## Position Simulator

This microservice simulates the vehicles moving around the country.

- When it starts up, it reads in a series of files. Those files contain test data that represents vehicle journeys.
- It runs in an infinite loop, and every few seconds it reads the next position from a file.
- Each file represents a single vehicle, and the name of the file becomes the name of the vehicle. To add more vehicles, you just add more files.
- Each file holds a long series of latitudes and longitudes — real GPS tracks recorded earlier.
- A microservice should do only one thing, and this one's single job is to simulate vehicle positions.
- Once it reads a position, it hands that data off to the queue (ActiveMQ). Because it runs forever and keeps producing new data over time, a queue is the natural way to handle this steady stream.

## Queue — ActiveMQ

A queue is a very common part of a microservice architecture. It lets us send data across the system without coupling the microservices together.

- The Producer is the service sending messages to ActiveMQ — here, the Position Simulator.
- The Consumer is the service receiving messages from the broker — here, the Position Tracker.
- ActiveMQ is a message broker. When a message is sent in it's "enqueued"; when a consumer reads it, it's "dequeued".

How the consumer actually receives messages:

1. The consumer (Position Tracker) connects and subscribes to the queue (`positionQueue`), creating a connection/session/consumer.
2. The broker (ActiveMQ) pushes messages to that consumer over the open TCP connection.
3. The consumer acknowledges (ACKs) the message. Only then does the broker treat it as successfully consumed.

## Position Tracker

This is the most important microservice and does the real heavy lifting.

- Its job is to read positions from the queue and run calculations on them, such as working out the speed of each vehicle.
- It also acts as a repository for vehicles, storing the history of where each vehicle has been.
- It exposes a REST interface so clients can fetch vehicle details:
  - `/vehicles` — all vehicles
  - `/vehicles/{vehicle-name}` — a single vehicle, e.g. `/vehicles/City%20Truck` (`%20` is the escaped space in "City Truck")
- Because it does the heavy work, this is the service that needs scaling in production (the simulator just generates data).

Storing history:

- The position history needs to be saved somewhere so it survives restarts. Originally it was kept in-memory (RAM), but that is not persistent.
- So the tracker stores history in MongoDB instead.
- The data is just a large collection of JSON-like documents with nothing relational about it, which makes MongoDB (a simple document database) a good fit.

## API Gateway

The frontend needs to talk to the backend, but in a microservice architecture we never let the frontend talk to the microservices directly.

Why not? Because the backend is in a constant state of flux. Microservices keep changing — they grow more complex, and their number goes up and down over time. A service like the Position Tracker might get so complex that we later split it into two services, or two small services might get merged into one. If the frontend talked to the microservices directly, every one of these backend changes would force a change in the frontend too.

So there should always be something in between that acts as a router between the frontend and the microservices. That something is a backend, and here we call it an API Gateway. Whether you call it a backend or an API Gateway, its purpose is the same: sit between the frontend and the microservices and route each request to the right service. It already knows how to talk to the microservices, so the frontend doesn't have to.

How it works here:

- The gateway is the single point of entry to the entire application — the frontend only ever talks to the gateway.
- Its job is to delegate each incoming call to the appropriate microservice.
- It uses simple mapping logic to decide where a request should go. For example, the frontend makes a REST call to `/api/vehicles`; the gateway intercepts it and, because it ends in `/vehicles`, forwards it to the Position Tracker.
- This keeps the frontend isolated from backend changes. As engineers add, split, or merge microservices, they only update the gateway's mapping — the frontend doesn't have to change.

![API Gateway routing — the browser calls /api/vehicles, the gateway forwards /vehicles to the Position Tracker](docs/images/api-gateway.png)

## Webapp

This is the user-facing part — a JavaScript single-page app built with Angular and served by an nginx web server.

- It shows the vehicles moving live on a map (using Leaflet).
- It lists the vehicles with details like name, last-seen time, and speed.
- When you select a vehicle, it draws the route history — the path the vehicle took from its start point to its current position.
- It only communicates with the API Gateway, never with the backend microservices directly.

---

# Concepts & Design Decisions

## Monolith vs Microservices

This Java application is a microservice-based app. But why have we shifted from the traditional monolith to a microservices architecture?

### Monolith

The traditional architecture is called a monolith — the entire system is deployed as a single unit.

- For a Java web application, this means a single WAR file containing the entire project.
- In real cases that WAR file doesn't fulfil just one business need — it fulfils many (e.g. a shopping site has product, cart, inventory, payment, and more), and these requirements keep growing.
- A global database backs the whole application, and every business area reads and writes to that same database.
- Often this database is even shared by other monolithic applications — a shared database like this is called an Integration Database.

#### Problems with the monolithic architecture

- The monolith eventually gets bloated — too big to manage easily.
- It becomes harder to change one business area without accidentally breaking another.
- As it grows, multiple teams end up working on the same application and start cutting across each other — changing the inventory means consulting other colleagues so you don't break their work.
- All the code is combined and deployed as one application, so shipping a single change means coordinating and releasing the entire monolith — which is slow.
  - For example, if I have to deploy a new change in inventory, I can't just ship that on its own — I have to wait, coordinate with other colleagues, and release the changes as one whole application, which is slow.

### Microservices

Microservices are about modularity and isolation — we break the entire system into self-contained, isolated components.

- Each microservice has separate code in a separate repo, and can be developed, deployed, and run on its own.
- They can run on their own hardware/server; the good practice is to deploy each microservice as a separate container.
- A microservice stays self-contained throughout its lifetime — changing the code of one does not affect another, since there's no direct code link or visibility between them.
- Microservices communicate via REST API calls (and can also pass messages between each other).
- Each microservice should be responsible for one business requirement.

#### Highly Cohesive and Loosely Coupled

Each microservice should be highly cohesive and loosely coupled.

- Highly cohesive — a microservice has a single set of responsibilities / handles one business requirement (e.g. payment service, authentication service, mailing service).
- Loosely coupled — minimize the interfaces (the service-to-service communication) between microservices. Tangled dependencies between many services defeat the purpose. But maintaining loose coupling is hard.

#### Databases in microservices

- Integration (shared) databases are not good for a microservice architecture:
  - They are not cohesive by design — they hold many different business areas.
  - They are not loosely coupled — any part of the system, and even other systems, can read and write to them.
- Each microservice should maintain its own database, and only that microservice can read and write to its own data store.
- Different microservices can use different types of databases (relational, NoSQL/big-data stores, etc.) as best suits their needs.

---

# Deployment on AWS EKS

## Creating the AWS Infrastructure

All of the AWS infrastructure for this project is provisioned with Terraform. The main building blocks are summarised below.

#### Prerequisites

| Tool | Why it's needed |
|------|-----------------|
| Terraform | To provision the AWS infrastructure as code |
| AWS CLI | To configure AWS credentials/profiles and talk to AWS |
| kubectl | To interact with the Kubernetes (EKS) cluster |
| eksctl | To create and manage EKS resources (e.g. IAM service accounts) |
| Helm | To install cluster add-ons like the AWS Load Balancer Controller |
| Docker | To build and push the service images |

#### Terraform

| Item | Detail |
|------|--------|
| Workspace | A separate Terraform workspace is used just for this infrastructure, keeping its state isolated from anything else |
| Backend (`backends/prod-backend.tfbackend`) | The backend is where Terraform keeps its state file — the record of every resource it has created and their current values. Here the state is stored remotely in an S3 bucket (`fleetman-tf-state`), encrypted, with versioning enabled, so it is safe, shareable, and recoverable |
| Variables (`prod-terraform.tfvars`) | The setup is parametrized — this file holds the values for the Terraform variables (region, CIDRs, names, feature toggles, etc.), so the same code can be reused across environments |
| Modules | Official [`terraform-aws-modules`](https://github.com/terraform-aws-modules) are used for most resources (VPC, EKS, ECR, Prometheus, Grafana, IAM); custom modules were written for the rest (e.g. CloudFront, EKS add-ons) |

<sub>**[more on terraform →](#using-terraform-for-infra-creation)**</sub>

#### AWS and Other Services

| Service | Why it's used |
|---------|---------------|
| [EKS cluster](#deploying-eks-cluster) | The Kubernetes cluster the whole application is deployed on |
| [VPC](#vpc) | EKS lives inside its own Virtual Private Cloud (private network) |
| [ECR](#ecr) | Stores the Docker images for our services |
| [Amazon MQ](#deploying-the-queue--amazon-mq) | Managed message broker for our queue |
| [MongoDB Atlas](#mongodb-atlas) | Managed MongoDB for storing vehicle position history |
| IAM | Identities, roles, and permissions for the cluster, nodes, and pods |
| ACM | Provisions/manages the TLS certificate for HTTPS (used by the load balancer and CloudFront) |
| Load Balancer | Part of the Load Balancer Controller — exposes the webapp (and any other service we want to expose) |
| CloudFront | CDN in front of the main webapp |
| CloudWatch | Stores and views logs |
| WAF | Web Application Firewall to protect the application |
| Helm | Kubernetes package manager — used to install cluster add-ons like the AWS Load Balancer Controller |

#### IAM

| User | Purpose |
|------|---------|
| devops | Used for infrastructure creation via Terraform |

#### EKS

| Component | Detail |
|-----------|--------|
| Control plane | Completely managed by AWS — we cannot access or scale it ourselves |
| Data plane | AWS-managed node group (AWS handles node creation) — where our application pods are deployed |
| IRSA | IAM Roles for Service Accounts — gives individual pods their own least-privilege AWS permissions through their Kubernetes service account |
| IAM roles | Roles for the EKS cluster and the worker node group |

EKS add-ons installed:

- CoreDNS — in-cluster DNS for service discovery
- eks-pod-identity-agent — lets pods assume IAM roles (pod identity)
- kube-proxy — manages network routing rules on each node
- vpc-cni — assigns VPC IP addresses to pods
- ebs-csi-driver — provisions EBS volumes for persistent storage

#### S3

We need two S3 buckets:

| Bucket | Purpose | Created by |
|--------|---------|-----------|
| `fleetman-tf-state` | Stores the Terraform state file | Manually (it must already exist before Terraform can use it as its backend) |
| `fleetman-codepipeline-artifacts` | Stores the artifacts passed between the stages of the AWS CodePipeline | Terraform |

#### How Each Service Is Deployed

| Service | Deployment |
|---------|-----------|
| Webapp | Static SPA served via CloudFront + S3 |
| Position Simulator, Position Tracker, API Gateway | Kubernetes Deployments in the [EKS cluster](#deploying-eks-cluster) |
| Queue | [Amazon MQ](#deploying-the-queue--amazon-mq) (managed ActiveMQ) |
| MongoDB (for Position Tracker) | [MongoDB Atlas](#mongodb-atlas) (managed) |

---

# Using Terraform for Infra Creation

**Why Terraform?** Terraform lets us define all of the AWS infrastructure as code instead of clicking around the console by hand. The biggest reason I chose it is how it manages **state**.

Terraform works on the idea of **desired state vs current state**:

- The **desired state** is what we declare in our `.tf` files — the infrastructure we *want* to exist.
- The **current state** is what actually exists, which Terraform tracks in a **state file**.
- When we run `terraform plan` / `apply`, Terraform compares the two and works out the difference, then makes only the changes needed to bring the real infrastructure in line with our code (creating, updating, or destroying resources as required).

This gives us infrastructure that is reproducible, version-controlled, reviewable, and easy to tear down and recreate — and it avoids configuration drift, because the state file is the single source of truth for what Terraform manages.

### Directory Structure

The `Infrastructure/` directory is organised into a root module and reusable child modules (only the key files are shown):

```
Infrastructure/
├── main/                            # Root module — run terraform from here
│   ├── init.tf                      # Provider + version setup
│   ├── backend.tf                   # Remote S3 backend declaration
│   ├── variables.tf                 # Variable definitions
│   ├── prod-terraform.tfvars        # Variable values for the prod environment
│   ├── backends/
│   │   └── prod-backend.tfbackend   # Backend config (state bucket, key, region)
│   ├── vpc.tf                       # Calls the vpc module
│   ├── eks.tf                       # Calls the eks module
│   ├── ecr.tf                       # Calls the ecr module
│   ├── cloudfront.tf
│   ├── monitoring.tf
│   └── output.tf
│
└── modules/                         # Reusable child modules
    ├── vpc/
    ├── eks/
    ├── eks-addons/
    ├── ecr/
    ├── cloudfront/
    ├── iam/
    └── monitoring/                  # each module: main.tf, variable.tf, output.tf
```

The root module (`main/`) wires everything together by calling the child modules under `modules/`, passing in the values from `prod-terraform.tfvars`.

### Root Module vs Child Modules

A quick note on terminology, since this setup has modules calling other modules:

- **Root module** — the top-level folder where you actually run Terraform. Here that's `Infrastructure/main/`. There is only ever one root module.
- **Child module** — any module that is called by another module. Everything under `modules/` is a child module.

In this project there's an extra layer, because my own modules wrap the official ones:

```
root (main/)  →  my module (modules/vpc)  →  official module (terraform-aws-modules/vpc/aws)
```

- `main/` is the **root**.
- `modules/vpc` is a **child** of the root — and at the same time it's the **parent (caller)** of the official module.
- The official `terraform-aws-modules/vpc/aws` is a **nested child** (a child of my child).

So "root" only ever refers to `main/`; anything inside `modules/` is a child, no matter how many layers deep the calls go.

### init.tf

This is the provider setup. Always pin the official AWS provider version so the builds stay reproducible.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.35.1"
    }
  }
}

provider "aws" {
  region = var.region
}
```

### Backend — prod-backend.tfbackend

The S3 bucket that holds the state must be created beforehand.

```hcl
bucket  = "fleetman-tf-state"
key     = "prod/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

### Deploying the Infrastructure

Clone the repo:

```bash
git clone https://github.com/priyanshi-sarad2/fleet-management-system.git
```

Create an IAM user with the permissions needed for infrastructure creation, then set up an AWS profile for it:

```bash
aws configure --profile fleetman-prod
```

Go into the root module and export the profile. The AWS account ID is kept out of version control, so it's passed in as an environment variable (`TF_VAR_account_id`), which Terraform automatically maps to the `account_id` variable:

```bash
cd Infrastructure/main
export AWS_PROFILE=fleetman-prod
export TF_VAR_account_id=<your-aws-account-id>
```

Initialise Terraform with the backend config:

```bash
terraform init -backend-config=backends/prod-backend.tfbackend
```

Create and select a workspace:

```bash
terraform workspace new fleetman-prod
terraform workspace select fleetman-prod
terraform workspace show
```

Review the plan, then apply:

```bash
terraform plan -var-file=prod-terraform.tfvars
terraform apply -var-file=prod-terraform.tfvars
```

---

# VPC

A VPC (Virtual Private Cloud) is a private, isolated network inside AWS that we fully control.

A key thing about a VPC is that every resource inside it can talk to every other resource over private IPs, simply because they are all part of the same network (subject to security groups and network ACLs) — no traffic needs to go over the public internet for them to reach each other.

For this project we create our own dedicated VPC. One thing worth noting: the **EKS control plane** runs in a **separate, AWS-managed VPC** that we don't see or control. Only the **data plane** — our worker nodes and the application pods — is deployed into the VPC we create here.

![VPC resource map — the fleetman-prod VPC with its 6 subnets across 4 AZs and 3 route tables](docs/images/vpc-resource-map.png)

### Subnets, CIDR and Availability Zones

A subnet is a smaller slice of the VPC's IP range. Two ideas make this clearer:

- **CIDR block** — the range of private IP addresses a network owns. Our VPC is given the CIDR `10.2.0.0/16`, which covers `10.2.0.0` – `10.2.255.255` (around 65,000 addresses). Every subnet then carves out a smaller piece of this range.
- **Availability Zone (AZ)** — a physically separate data centre within the region. Each subnet lives in exactly one AZ. Spreading subnets across multiple AZs (`us-east-1a`, `1b`, `1c`, `1d`) gives high availability — if one AZ goes down, resources in the others keep running.

We split the VPC range into public and private subnets, each a `/24` block (256 addresses):

**Public subnets (2)** — `10.2.1.0/24` and `10.2.2.0/24`. A public subnet has a route to the internet through the internet gateway, so resources here can be reached from the internet and can reach out to it. Resources here can be given a **public IP** (in addition to their private IP), which is the address the outside world uses to reach them. We use these subnets for the **load balancer** and the **NAT gateway**. Because the load balancer sits in a public subnet, it is internet-facing and gets a **public DNS name** (and public IP) — this is the entry point users actually hit from the internet, and it then forwards the traffic inward to the pods running in the private subnets. (Two public subnets are used, in two different AZs, because an internet-facing load balancer needs a subnet in each AZ it serves.)

**Private subnets (4)** — `10.2.10.0/24`, `10.2.11.0/24`, `10.2.12.0/24`, `10.2.13.0/24`. A private subnet has **no** direct route to the internet. Resources here only get a **private IP** (an address that is only reachable from inside the VPC) and no public IP, so nothing on the internet can address them directly. This is where the **EKS worker nodes and the application pods run**. Keeping them private is more secure — incoming traffic has to go through the load balancer in the public subnet first, and outbound traffic goes out via the NAT gateway.

### Internet Gateway

An internet gateway is what connects the VPC to the public internet. Without it, even the public subnets would have no way in or out.

We need it so that resources in the **public subnets** (like the load balancer and the NAT gateway) can send and receive traffic to and from the internet. It's attached to the VPC, and the public route table sends internet-bound traffic to it.

### NAT Gateway

The pods and nodes live in **private subnets**, which have no route to the internet. But they still need **outbound** internet access — for example, to pull container images, download packages, or call external APIs. Without a NAT gateway, apps inside the pods would have no internet access at all.

This is what the NAT (Network Address Translation) gateway solves:

- The NAT gateway sits in a **public subnet** and is given an **Elastic IP** (a fixed public IP address).
- When a pod in a private subnet wants to reach the internet, its traffic is routed to the NAT gateway.
- The NAT gateway swaps the pod's private source IP for its own Elastic IP and sends the request out through the internet gateway.
- Return traffic comes back to the NAT gateway, which forwards it to the right private resource.

The important property is that it only allows **outbound** connections — the internet can't start a connection *into* the private subnets through the NAT gateway. So pods get internet access for pulling things they need, while staying unreachable from outside.

### Route Tables

A route table is a set of rules that decides where network traffic is sent. Each subnet is associated with one route table.

**Public route table** — associated with the public subnets. It has a route that sends internet-bound traffic (`0.0.0.0/0`) to the **internet gateway**, which is what makes those subnets "public".

![Public route table routes — 0.0.0.0/0 points to the internet gateway, 10.2.0.0/16 is local](docs/images/route-table-public.png)

**Private route table** — associated with the private subnets. Its internet-bound traffic (`0.0.0.0/0`) is sent to the **NAT gateway** instead. This is how private resources get outbound internet access without being directly exposed to the internet.

![Private route table routes — 0.0.0.0/0 points to the NAT gateway, 10.2.0.0/16 is local](docs/images/route-table-private.png)

---

# ECR

ECR (Elastic Container Registry) is AWS's private Docker image registry. After we build the Docker image for a service, we push it to ECR, and the EKS cluster pulls the image from there when it deploys the pods.

We use **3 ECR repositories — one for each of the 3 services that run in the cluster** (Position Simulator, Position Tracker, API Gateway). Keeping a separate repository per service keeps their images cleanly isolated and independently versioned.

### Image retention

Since this is a production setup, we don't want to keep every image forever — old images pile up and add storage cost. So each repository has a **lifecycle policy** that keeps only the most recent images and automatically deletes the older ones.

![ECR lifecycle policy rule — keep the last 5 tagged images (tag filter "v"), action Expire](docs/images/ecr-lifecycle-policy.png)

Looking at the lifecycle policy rule above:

- We keep the **latest 5 images**. Five is a sensible production default — enough history to roll back a few versions if a deploy goes wrong, without letting images grow unbounded.
- Only images whose tag starts with **`v`** are counted (releases are tagged `v1`, `v2`, `v3`, …). This is the `tagPrefixList = ["v"]` part of the rule.
- The rule type is "more than N" (`imageCountMoreThan`), so once a repository has **more than 5** such tagged images, the rule's action is to `expire` (delete) the **oldest** images beyond the newest 5.

How a delete actually happens: as you push `v1`, `v2`, `v3`, `v4`, `v5`, all 5 are kept. The moment you push `v6`, the repository now has 6 images, which is more than 5 — so the oldest one (`v1`) is automatically expired, always leaving the 5 most recent versions.

---

# Deploying the Queue — Amazon MQ

**What is Amazon MQ?** Amazon MQ is a managed message-broker service from AWS. Instead of running and maintaining a message broker yourself, AWS runs popular open-source brokers for you — **ActiveMQ** and **RabbitMQ** — and handles the servers, storage, patching, and availability.

**Why Amazon MQ with the ActiveMQ engine?** The application already speaks **ActiveMQ** — the Position Simulator and Position Tracker connect using JMS/OpenWire (via `spring-boot-starter-activemq`). Amazon MQ's ActiveMQ engine is a managed, drop-in replacement for a self-hosted ActiveMQ broker: we get the same protocol and the same app behaviour, but without managing the broker ourselves — and **without rewriting any application code**. (A native AWS option like SQS would have meant rewriting the producer and consumer, since SQS isn't JMS — Java Message Service.)

### The broker

- A single-instance ActiveMQ broker (`mq.t3.micro`, engine version `5.19`), named **`fleetman-mq`**.
- It is deployed **inside a private subnet** of our VPC and is **not publicly accessible** — so it can only be reached from within the VPC, never from the internet.
- Its security group allows inbound traffic on **port `61617`** (OpenWire over TLS — the port JMS uses). This is what lets both the **Position Simulator** (producer) and the **Position Tracker** (consumer) reach the broker to send and receive messages.
- Two users are created: an **admin** user (web-console access) and an **application** user (`fleetman-app`) that the services use to connect. The passwords are auto-generated and stored securely in **SSM Parameter Store** (the password as an encrypted SecureString).

![Amazon MQ broker fleetman-mq in Running state — Apache ActiveMQ, single-instance, mq.t3.micro](docs/images/mq-broker-running.png)

### How the apps connect to the broker

Both the Position Simulator and the Position Tracker connect to the **same** broker, so **both** services need the same three values, supplied as environment variables:

| Variable | Purpose |
|----------|---------|
| `ACTIVEMQ_BROKER_URL` | The broker's OpenWire TLS endpoint, e.g. `ssl://b-xxxx-xxxx.mq.us-east-1.amazonaws.com:61617` |
| `ACTIVEMQ_USER` | The application username (`fleetman-app`) |
| `ACTIVEMQ_PASSWORD` | The application user's password (read from SSM) |

These are configured in each service's properties file:

- `k8s-fleetman-position-simulator/src/main/resources/application-production-microservice.properties`
- `k8s-fleetman-position-tracker/src/main/resources/application-production-microservice.properties`

Both files have the same three lines, each reading from an environment variable:

```properties
spring.activemq.broker-url=${ACTIVEMQ_BROKER_URL:tcp://fleetman-queue.default.svc.cluster.local:61616}
spring.activemq.user=${ACTIVEMQ_USER:}
spring.activemq.password=${ACTIVEMQ_PASSWORD:}
```

If the env vars aren't set, the apps fall back to the old in-cluster broker URL with no credentials (used for local development).

### Getting the broker credentials

The broker passwords are auto-generated and stored in **SSM Parameter Store** (as encrypted `SecureString`s), so they never live in the repo. Retrieve the application user's password with:

```bash
aws ssm get-parameter \
  --name "/mq/mq_application_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --profile fleetman-prod --region us-east-1
```

For the admin password (web console), use `/mq/mq_admin_password` instead. The `--with-decryption` flag is required because the values are stored as encrypted `SecureString`s. The usernames are stored alongside them at `/mq/mq_application_username` and `/mq/mq_admin_username`.

---

# MongoDB Atlas

**What is MongoDB?** MongoDB is a NoSQL **document database**. Instead of tables and rows like a relational database, it stores data as flexible, JSON-like documents.

**Why MongoDB for this project?** The Position Tracker needs to store the **history of where every vehicle has been**. Each record is a simple JSON-like document — vehicle name, latitude, longitude, timestamp, and speed. This history is just a large, ever-growing collection of such documents with nothing relational about it, so a document database is a natural fit. It also lets the tracker keep the history **durably** instead of in memory (which is lost whenever the pod restarts).

**Why MongoDB Atlas?** Atlas is MongoDB's fully-managed cloud service. Rather than running and maintaining MongoDB ourselves inside the cluster — handling storage, backups, upgrades, and availability — Atlas manages all of that for us, and the Position Tracker simply connects to it.

### How the Position Tracker connects

The connection is configured in the Position Tracker's properties file:

`k8s-fleetman-position-tracker/src/main/resources/application-production-microservice.properties`

```properties
spring.data.mongodb.uri=${MONGODB_URI:mongodb://fleetman-mongodb.default.svc.cluster.local:27017/fleetman}
```

- The URI comes from the **`MONGODB_URI`** environment variable, supplied to the pod (ideally from a Kubernetes Secret), so the connection string — which contains the password — never lives in the repo.
- For Atlas, `MONGODB_URI` is set to the SRV connection string, e.g. `mongodb+srv://fleetman:<password>@fleetman.xxxxx.mongodb.net/fleetman?appName=fleetman`.
- If `MONGODB_URI` isn't set, it falls back to the in-cluster MongoDB URL, which is handy for local development.

### Making the MongoDB connection secure

Atlas is reachable over the internet, so by default anyone with the credentials could try to connect. To lock it down, Atlas has a **Network Access → IP Access List**, where we add **only our VPC's NAT gateway Elastic IP**.

Why the NAT Elastic IP?

- The Position Tracker pods run in **private subnets**, which have no direct internet access.
- To reach Atlas (which lives outside the VPC, on the internet), the pods make an **outbound** connection — and since they're in private subnets, that traffic goes out through the **NAT gateway**.
- The NAT gateway uses a fixed **Elastic IP**, so from Atlas's point of view, every connection from our cluster appears to come from that one IP. The Elastic IP matters because it is **static** — it stays the same, so it's safe to allowlist.

The IP is added as a **`/32`** entry (e.g. `<nat-eip>/32`). A `/32` CIDR means **exactly one IP address** — a single host — so only that precise address is allowed, nothing wider.

By adding only this IP to the access list, the Atlas cluster can **only be reached from our cluster's NAT IP** — nothing else on the internet can connect to it, even with the password.

![MongoDB Atlas IP Access List — only the fleetman VPC NAT gateway Elastic IP is allowed](docs/images/mongodb-ip-access-list.png)

---

# Deploying EKS cluster

An EKS cluster has two major components: the **control plane** and the **data plane**.

### Control plane

The control plane is **completely managed by AWS** — we don't provision, access (SSH into), or scale it ourselves. AWS runs it on its **own separate infrastructure** (a separate AWS-managed account/VPC, not our VPC) and takes care of the Kubernetes API server, etcd, scheduler, and controller manager, along with their high availability and patching.

A key billing point: the control plane has a **flat hourly rate**. Even if we have **zero worker nodes** and aren't running any workloads, we're charged for the control plane for as long as the cluster exists. So a cluster that's just sitting idle still costs money — worth remembering when you spin clusters up for practice.

### Data plane

The data plane is the **worker nodes where the pods actually run**. EKS gives three options for it:

- **Self-managed node group** — you create and manage the EC2 instances yourself (most control, most operational work).
- **AWS-managed node group** — AWS provisions and manages the lifecycle of the EC2 worker nodes (AMIs, updates, scaling). **This is what this project uses.**
- **Fargate** — serverless; no nodes to manage at all, pods run on capacity AWS provisions on demand.

This project uses the **AWS-managed node group**: AWS handles the node provisioning and lifecycle, while we just declare the instance type and the min/max/desired sizes (in `prod-terraform.tfvars`). The node group is created automatically whenever the EKS cluster is created.

---

## Control plane ENI, data plane ENI, and bi-directional networking

**ENI = Elastic Network Interface.** Think of an ENI as a **virtual network card** for a server. It plugs the server into a subnet and gives it an **IP address** — its identity on the network. Anything in a VPC that sends or receives traffic does so through an ENI.

**A quick primer on ENIs and addressing.** In any network, traffic flow needs a **source** and a **destination**, and each needs an **address**. In AWS, a server gets its address through an **ENI (Elastic Network Interface)**. An ENI is attached to a **subnet** (a network), and from that subnet it receives an **IP** — private or public depending on the subnet — and that IP is the server's address. You then control what traffic is allowed to and from it using a **security group** (AWS's equivalent of a firewall like UFW on-prem). So in short: both the source and the destination need an ENI → which gives them an address → and security groups control the traffic between them.

**Why this matters for EKS.** A Kubernetes cluster only works if the **control plane and the data plane can talk to each other — both ways**. For that, both sides must have an address in the **same network**.

- **Data plane** — our worker nodes (the AWS-managed node group) are EC2 instances deployed into our VPC's **private subnets**. Each instance automatically gets an **ENI** in that subnet, so it gets a **private IP** — it already has an address and is already part of our VPC.
- **Control plane** — this is managed by AWS and lives in a **separate, AWS-managed network/account**, so by default it is *not* in our VPC. When we create the cluster, AWS creates **ENIs for the control plane** and places them in the **subnets of our VPC** that we specify. We don't attach them by hand — we just tell EKS which VPC/subnets to use, and EKS creates the control-plane ENIs there.

**What this achieves:**

- Because the control-plane ENIs sit in our **private subnets**, they get **private IPs** from our network — so the control plane effectively becomes part of our VPC.
- We also attach a **security group** to these ENIs. In EKS this is the **cluster security group**. The data-plane nodes have their **own separate node security group**, and rules are configured between the two so the control plane and the nodes are allowed to talk to each other.
- Now both sides have an address in the same network, and the security group allows them to communicate. This enables the **bi-directional traffic** that defines a Kubernetes cluster:
  - **control plane → data plane:** the kube-apiserver reaches the **kubelet** on each node (to schedule/inspect pods),
  - **data plane → control plane:** nodes **register** themselves with the cluster and continuously **report their status** back to the kube-apiserver.

That two-way flow between control plane and data plane — made possible by attaching the control-plane ENIs into our VPC's subnets — is exactly what turns these separate pieces into one working cluster.

The diagram below shows the idea: the control plane lives in AWS's own network, but AWS places its **ENIs into our VPC's private subnets**, and the worker nodes have their own ENIs in those same subnets — so the two can talk both ways.

```mermaid
flowchart LR
    subgraph AWSNET["AWS-managed network"]
        CP["Control plane<br/>(API server, etcd, scheduler)"]
    end

    subgraph OURVPC["Our VPC — private subnets"]
        CPENI["Control plane ENIs<br/>private IP + cluster SG"]
        NODES["Worker nodes / data plane<br/>node ENIs + node SG"]
    end

    CP -. "managed by AWS" .- CPENI
    CPENI <-->|"bi-directional traffic"| NODES
```
