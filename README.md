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
| Docker | To build and push the service images |

#### Terraform

| Item | Detail |
|------|--------|
| Workspace | A separate Terraform workspace is used just for this infrastructure, keeping its state isolated from anything else |
| Backend (`backends/prod-backend.tfbackend`) | The backend is where Terraform keeps its state file — the record of every resource it has created and their current values. Here the state is stored remotely in an S3 bucket (`fleetman-tf-state`), encrypted, with versioning enabled, so it is safe, shareable, and recoverable |
| Variables (`prod-terraform.tfvars`) | The setup is parametrized — this file holds the values for the Terraform variables (region, CIDRs, names, feature toggles, etc.), so the same code can be reused across environments |
| Modules | Official [`terraform-aws-modules`](https://github.com/terraform-aws-modules) are used for most resources (VPC, EKS, ECR, Prometheus, Grafana, IAM); custom modules were written for the rest (e.g. CloudFront, EKS add-ons) |

<sub>**[more on terraform →](#using-terraform-for-infra-creation)**</sub>

#### AWS Services

| Service | Why it's used |
|---------|---------------|
| EKS cluster | The Kubernetes cluster the whole application is deployed on |
| VPC | EKS lives inside its own Virtual Private Cloud (private network) |
| IAM | Identities, roles, and permissions for the cluster, nodes, and pods |
| ECR | Stores the Docker images for our services |
| Load Balancer | Part of the Load Balancer Controller — exposes the webapp (and any other service we want to expose) |
| CloudFront | CDN in front of the main webapp |
| CloudWatch | Stores and views logs |
| Amazon MQ | Managed message broker for our queue |
| MongoDB Atlas | Managed MongoDB for storing vehicle position history |
| WAF | Web Application Firewall to protect the application |

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
| Position Simulator, Position Tracker, API Gateway | Kubernetes Deployments in the EKS cluster |
| Queue | Amazon MQ (managed ActiveMQ) |
| MongoDB (for Position Tracker) | MongoDB Atlas (managed) |

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

Go into the root module and export the profile:

```bash
cd Infrastructure/main
export AWS_PROFILE=fleetman-prod
```

Initialise Terraform with the backend config:

```bash
terraform init -backend-config=backends/prod-backend.tfbackend
```

Create and select a workspace:

```bash
terraform workspace new fleetman-prod
terraform workspace select fleetman-prod
```

Review the plan, then apply:

```bash
terraform plan -var-file=prod-terraform.tfvars
terraform apply -var-file=prod-terraform.tfvars
```

---

# VPC

EKS gets its own dedicated VPC (a Virtual Private Cloud — a private, isolated network inside AWS), so the cluster is fully network-isolated from everything else.

A key thing about a VPC is that **every resource inside it can talk to every other resource by default** (subject to security groups and network ACLs). So the EC2 worker nodes, the pods, and other resources in the VPC can reach each other over private IPs without going anywhere near the public internet. The VPC is essentially the private network that holds the whole cluster.

Inside the VPC we have:

### Subnets

A subnet is just a slice of the VPC's IP range. Each subnet lives in one Availability Zone, and we split them into public and private.

**Public subnets (2)** — A public subnet is one that has a route to the internet through an internet gateway, so resources placed here can be reached from the internet (and reach out to it). We use the public subnets for the **load balancer** and the **NAT gateway** — things that need to face the internet.

**Private subnets (4)** — A private subnet has **no** direct route to the internet. This is where **EKS is deployed and the application pods run**. Keeping the nodes and pods private is more secure, because they cannot be reached directly from the internet — anything coming in has to go through the load balancer in the public subnet first.

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

**Private route table** — associated with the private subnets. Its internet-bound traffic (`0.0.0.0/0`) is sent to the **NAT gateway** instead. This is how private resources get outbound internet access without being directly exposed to the internet.
