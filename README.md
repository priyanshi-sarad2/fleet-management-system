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

1. The Position Simulator pretends to be the moving vehicles and keeps sending their positions to a queue.
2. The Queue (ActiveMQ) holds those position messages so services stay decoupled.
3. The Position Tracker reads messages off the queue, calculates speed, stores history in MongoDB, and exposes a REST API.
4. The API Gateway is the single entry point the frontend talks to; it forwards requests to the right backend service.
5. The Webapp (Angular) shows the vehicles moving live on a map, with a list and route history.

#### The 5 Microservices

| Service | Tech |
|---------|------|
| **Position Simulator** | Java / Spring Boot |
| **Queue** | ActiveMQ |
| **Position Tracker** | Spring Boot + MongoDB |
| **API Gateway** | Spring Boot + Feign + Hystrix |
| **Webapp** | Angular 6 + Leaflet + nginx |

---

# How Each Part Works

## Position Simulator

This microservice simulates the vehicles moving around the country.

- When it starts up, it reads in a series of files. Those files contain test data that represents vehicle journeys.
- It runs in an infinite loop, and every few seconds it reads the next position from a file.
- Each file represents a single vehicle, and the name of the file becomes the name of the vehicle. To add more vehicles, you just add more files.
- Each file holds a long series of latitudes and longitudes — real GPS tracks recorded earlier.
- A microservice should do only one thing, and this one's single job is to simulate vehicle positions.
- Once it reads a position, it hands that data off to the queue (ActiveMQ). Because it runs forever and keeps producing new data over time, a queue is the natural way to handle this steady stream.

Notes on how it's wired:

- The simulator is isolated and does not expose any ports — nothing calls it directly, so it doesn't need its own Service.
- It only needs an environment variable set (telling it where the queue is).
- The queue, on the other hand, must be reachable (via a ClusterIP service) so the simulator can send messages to it.

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

- The position history needs to be saved somewhere so it survives restarts. Originally it was kept in-memory (RAM), but that is not persistent — it's lost whenever the pod is deleted/recreated, and the service can also run out of RAM.
- So the tracker stores history in MongoDB instead.
- The data is just a large collection of JSON-like documents with nothing relational about it, which makes MongoDB (a simple document database) a good fit.

## API Gateway

The frontend needs to talk to the backend, but it is not good practice for a frontend to call individual microservices directly. That's why we put an API Gateway in front.

- The gateway becomes the single point of entry to the entire application — the frontend only ever talks to the gateway.
- Its job is to delegate each incoming call to the appropriate microservice, using simple mapping logic. For example, a request ending in `/vehicles` gets forwarded to the Position Tracker.
- This keeps the frontend isolated from backend changes. As engineers add new microservices or split existing ones, they only update the gateway's mapping — the frontend doesn't have to change.

## Webapp

This is the user-facing part — a JavaScript single-page app built with Angular and served by an nginx web server.

- It shows the vehicles moving live on a map (using Leaflet).
- It lists the vehicles with details like name, last-seen time, and speed.
- When you select a vehicle, it draws the route history — the path the vehicle took from its start point to its current position.
- It only communicates with the API Gateway, never with the backend microservices directly.

## MongoDB

- A simple document database that easily stores JSON-like data.
- Used by the Position Tracker to persist vehicle position history so it survives pod restarts.
- In Kubernetes, a pod's local data is lost when the pod is destroyed, so this data is made durable using persistent volumes (backed by AWS EBS in the cloud deployment).

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
