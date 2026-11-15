Screenshots are not included yet because this workspace has no Minikube or kubectl executable, so no live deployment output could be captured without fabricating evidence.

After deploying, save these real captures here before submitting:
- pods.png: terminal showing `kubectl get pods -o wide` with all four pods Ready.
- logs.png: terminal showing successful gateway proxy log lines after requesting all three API routes.
- service-test.png: terminal showing the port-forward command and successful curl responses.