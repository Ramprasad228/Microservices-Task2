# Microservices on Minikube

This package deploys four Node.js services into a Minikube cluster. The services use ClusterIP for in-cluster discovery; the gateway calls the other services by Kubernetes DNS name. Each Deployment defines resource requests and limits plus HTTP liveness and readiness probes against `/health`.

## Prerequisites

- Windows 10/11 with Docker Desktop running, or another supported Minikube driver.
- Minikube and kubectl installed and available in PowerShell.
- This `submission` directory extracted into the project root, next to the `Microservices` directory. The Dockerfiles are in each service's source directory.

Confirm the tools are available:

```powershell
minikube version
kubectl version --client
docker version
```

## Start Minikube and Build Images

Start a cluster with Docker Desktop as its driver:

```powershell
minikube start --driver=docker
kubectl get nodes
```

Build directly into Minikube's image store. This matches the manifest's `imagePullPolicy: Never`, so Kubernetes won't try to pull these local images from a registry:

```powershell
minikube image build -t user-service:1.0.0 .\Microservices\user-service
minikube image build -t product-service:1.0.0 .\Microservices\product-service
minikube image build -t order-service:1.0.0 .\Microservices\order-service
minikube image build -t gateway-service:1.0.0 .\Microservices\gateway-service
minikube image ls
```

## Deploy

Run these commands from the project root (the directory containing `submission` and `Microservices`). Apply Services first so DNS names are registered, then Deployments:

```powershell
kubectl apply -f .\submission\services\
kubectl apply -f .\submission\deployments\
kubectl rollout status deployment/user-service
kubectl rollout status deployment/product-service
kubectl rollout status deployment/order-service
kubectl rollout status deployment/gateway-service
kubectl get pods -o wide
kubectl get services
```

All four pods should show `1/1` Ready. The Service names (`user-service`, `product-service`, `order-service`, and `gateway-service`) are the stable in-cluster DNS names used for service discovery.

## Test the Services

Forward the gateway Service to the local machine. Keep this command running in its own PowerShell window:

```powershell
kubectl port-forward service/gateway-service 3003:3003
```

In a second window, test gateway proxy routes and order creation:

```powershell
curl.exe http://localhost:3003/health
curl.exe http://localhost:3003/api/users
curl.exe http://localhost:3003/api/products
curl.exe http://localhost:3003/api/orders
curl.exe -X POST http://localhost:3003/api/orders -H "Content-Type: application/json" -d '{"userId":1,"productId":1}'
```

To test cluster DNS and direct service access without port-forwarding, run a temporary curl pod:

```powershell
kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:8.10.1 --command -- curl -fsS http://user-service:3000/users
kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:8.10.1 --command -- curl -fsS http://product-service:3001/products
kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:8.10.1 --command -- curl -fsS http://gateway-service:3003/api/orders
```

The direct-access commands create a short-lived diagnostic pod and may need internet access to pull the curl image. Gateway access exercises inter-service communication. To capture its successful proxy calls, make requests and inspect the gateway logs:

```powershell
kubectl logs deployment/gateway-service
```

Expected log lines include `GET /api/users -> http://user-service:3000` and equivalent product/order routes.

## Optional Ingress

Enable Minikube's NGINX Ingress controller and apply the optional manifest:

```powershell
minikube addons enable ingress
kubectl apply -f .\submission\ingress\ingress.yaml
kubectl get ingress
minikube ip
```

Add `microservices.local` and the displayed Minikube IP to the Windows hosts file at `%SystemRoot%\System32\drivers\etc\hosts` (editing it requires Administrator permissions). Then test:

```powershell
curl.exe http://microservices.local/api/users
curl.exe http://microservices.local/api/products
curl.exe http://microservices.local/api/orders
```

Ingress is optional; port-forwarding works without it.

## Screenshots

Save genuine terminal screenshots in `submission/screenshots/` before submitting:

- `pods.png`: `kubectl get pods -o wide` with all four pods Ready.
- `logs.png`: gateway logs after requests to the users, products, and orders routes.
- `service-test.png`: port-forwarded curl commands and their successful responses.

The screenshots are not pre-populated because no Minikube or kubectl executable is available in the authoring environment; no cluster output has been fabricated.

## Troubleshooting

- `ErrImageNeverPull` or `ImagePullBackOff`: confirm the four `minikube image build` commands completed and that each image appears in `minikube image ls`. Build with the exact image tag used in the Deployment manifest.
- A pod is not Ready: inspect `kubectl describe pod <pod-name>` and `kubectl logs deployment/<service-name>`. Verify that the service listens on its declared port and serves `/health`.
- Gateway returns HTTP 500: check `kubectl get endpoints`, confirm the backend Services select Ready pods, and inspect `kubectl logs deployment/gateway-service`. The gateway URL environment variables should point to the matching Service name and port.
- Port-forward fails: check `kubectl get pods` and `kubectl get services`, then retry `kubectl port-forward service/gateway-service 3003:3003`.
- Ingress returns 404 or cannot resolve: confirm the ingress addon is enabled, `kubectl get ingress` shows the host rule, and the Minikube IP/hostname entry is correct.

## Remove Resources

```powershell
kubectl delete -f .\submission\ingress\ingress.yaml
kubectl delete -f .\submission\deployments\
kubectl delete -f .\submission\services\
```