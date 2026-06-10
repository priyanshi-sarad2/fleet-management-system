# fleet-management-system

## The 5 Microservices

| Service | Tech | Role |
|---------|------|------|
| **Position Simulator** | Java / Spring Boot | Generates fake GPS data from ~38 route files, publishes to queue |
| **Queue** | ActiveMQ | Message broker (decouples services) |
| **Position Tracker** | Spring Boot + MongoDB | Consumes positions, stores them, exposes REST API |
| **API Gateway** | Spring Boot + Feign + Hystrix | REST facade + WebSocket/STOMP push to frontend |
| **Webapp** | Angular 6 + Leaflet + nginx | Live map UI with vehicle list and route history |

---

# Concepts & Design Decisions

## Monolith vs Microservices

This Java application is a **microservice-based app**. But why have we shifted from the traditional monolith to a microservices architecture?

### Monolith

The traditional architecture is called a **monolith** — the entire system is deployed as a single unit.

- For a Java web application, this means a **single WAR file** containing the entire project.
- In real cases that WAR file doesn't fulfil just one business need — it fulfils **many** (e.g. a shopping site has product, cart, inventory, payment, and more), and these requirements keep growing.
- A **global database** backs the whole application, and every business area reads and writes to that same database.
- Often this database is even **shared by other monolithic applications** — a shared database like this is called an **Integration Database**.

**Problems with the monolithic architecture**

- The monolith eventually gets **bloated** — too big to manage easily.
- It becomes harder to change one business area without **accidentally breaking another**.
- As it grows, **multiple teams** end up working on the same application and start cutting across each other — changing the inventory means consulting other colleagues so you don't break their work.
- All the code is combined and **deployed as one application**, so shipping a single change means **coordinating and releasing the entire monolith** — which is slow.
  - For example, if I have to deploy a new change in **inventory**, I can't just ship that on its own — I have to wait, coordinate with other colleagues, and release the changes as one whole application, which is slow.

### Microservices

Microservices are about **modularity and isolation** — we break the entire system into self-contained, isolated components.

- Each microservice has **separate code in a separate repo**, and can be **developed, deployed, and run on its own**.
- They can run on their own hardware/server; the good practice is to **deploy each microservice as a separate container**.
- A microservice stays **self-contained** throughout its lifetime — changing the code of one does **not** affect another, since there's no direct code link or visibility between them.
- Microservices **communicate via REST API calls** (and can also pass **messages** between each other).
- Each microservice should be responsible for **one business requirement**.

**Each microservice should be Highly Cohesive and Loosely Coupled**

- **Highly cohesive** — a microservice has a single set of responsibilities / handles one business requirement (e.g. payment service, authentication service, mailing service).
- **Loosely coupled** — minimize the interfaces (the service-to-service communication) between microservices. Tangled dependencies between many services defeat the purpose. Maintaining loose coupling is **hard**.

**Databases in microservices**

- Integration (shared) databases are **not good** for a microservice architecture:
  - They are **not cohesive** by design — they hold many different business areas.
  - They are **not loosely coupled** — any part of the system, and even other systems, can read and write to them.
- Each microservice should maintain **its own database**, and **only that microservice** can read and write to its own data store.
- Different microservices can use **different types of databases** (relational, NoSQL/big-data stores, etc.) as best suits their needs.
