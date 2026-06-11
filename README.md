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

## Creating the AWS Infrastructure — Terraform

All of the AWS infrastructure for this project is provisioned with Terraform. The main building blocks are summarised below.

### Terraform

| Item | Detail |
|------|--------|
| Workspace | A separate Terraform workspace is used just for this infrastructure, keeping its state isolated from anything else |
| Backend (`backends/prod-backend.tfbackend`) | The backend is where Terraform keeps its state file — the record of every resource it has created and their current values. Here the state is stored remotely in an S3 bucket (`fleetman-tf-state`), encrypted, with versioning enabled, so it is safe, shareable, and recoverable |
| Variables (`prod-terraform.tfvars`) | The setup is parametrized — this file holds the values for the Terraform variables (region, CIDRs, names, feature toggles, etc.), so the same code can be reused across environments |
| Modules | Official [`terraform-aws-modules`](https://github.com/terraform-aws-modules) are used for most resources (VPC, EKS, ECR, Prometheus, Grafana, IAM); custom modules were written for the rest (e.g. CloudFront, EKS add-ons) |

### AWS Services

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

### Inside the VPC

| Component | Why it's used |
|-----------|---------------|
| 2 public subnets | For the load balancer and the NAT gateway |
| 4 private subnets | Where EKS is deployed and the application pods run |
| Internet gateway | Lets resources in the public subnets reach the internet |
| NAT gateway | Provides outbound internet access for resources in the private subnets |
| Public route table | Routing for the public subnets (via the internet gateway) |
| Private route table | Routing for the private subnets (via the NAT gateway) |

EKS gets its own dedicated VPC (separate from anything else), so the cluster is fully network-isolated.

### EKS

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

### S3

We need two S3 buckets:

| Bucket | Purpose | Created by |
|--------|---------|-----------|
| `fleetman-tf-state` | Stores the Terraform state file | Manually (it must already exist before Terraform can use it as its backend) |
| `fleetman-codepipeline-artifacts` | Stores the artifacts passed between the stages of the AWS CodePipeline | Terraform |

## How Each Service Is Deployed

| Service | Deployment |
|---------|-----------|
| Webapp | Static SPA served via CloudFront + S3 |
| Position Simulator, Position Tracker, API Gateway | Kubernetes Deployments in the EKS cluster |
| Queue | Amazon MQ (managed ActiveMQ) |
| MongoDB (for Position Tracker) | MongoDB Atlas (managed) |
