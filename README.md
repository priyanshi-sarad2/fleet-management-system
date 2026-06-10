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
