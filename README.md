# Microservices on Kubernetes

This repository contains the User, Product, Order, and Gateway Node.js services, Dockerfiles for building their local images, and Kubernetes deployment artifacts.

The [step-by-step Minikube deployment guide](submission/README.md) includes setup, image builds, `kubectl apply`, service and gateway tests, troubleshooting, and the captured evidence screenshots in `submission/screenshots/`.

## Deployment Evidence

**Running Pods**

![kubectl get pods output showing all four services Ready](submission/screenshots/pods.png)

**Service Communication Logs**

![Gateway logs showing requests routed to the user, product, and order services](submission/screenshots/logs.png)

**Port-Forwarded Tests**

![Gateway health and API responses tested through port-forwarding](submission/screenshots/service-test.png)

**Ingress Routing**

![Ingress routes for users, products, orders, and health returning HTTP 200](submission/screenshots/ingress-test.png)
