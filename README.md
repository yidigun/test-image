# HTTP Route Test Image

## Dockerfile License

It's just free. (Public Domain)

See https://github.com/yidigun/test-image

## Changelog

* 3.0 - Ported from node.js to Go. Added support for Windows containers.
* 2.1 - Upgrade node to ```22.x``` and express to ```4.19```.
* 2.0 - Change platform from php to node/express.
* 1.0 - First release (deprecated)

## Use Image

This image is useful when settting up k8s cluster and ingress configuration,
to check application server can acquire correct client address.

```shell
docker run -d -e SERVERPORT=8080 -p 8080:8080/tcp yidigun/test-image:latest

curl -v http://localhost:8080
curl -v -H 'X-Forwarded-For: 192.168.112.22' http://localhost:8080
curl -v -H 'Accept: application/json' http://localhost:8080
```

### Kubernetes Config

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-image
  labels:
    app: test-image
spec:
  replicas: 10
  selector:
    matchLabels:
      app: test-image
  template:
    metadata:
      labels:
        app: test-image
    spec:
      containers:
        - name: test-image
          image: docker.io/yidigun/test-image:latest
          env:
            - name: SERVERPORT
              value: "8080"
---
apiVersion: v1
kind: Service
metadata:
  name: test-image-service
spec:
  selector:
    app: test-image
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-image-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /test-image
            pathType: Prefix
            backend:
              service:
                name: test-image-service
                port:
                  number: 80
    - host: "test-image.yidigun.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: test-image-service
                port:
                  number: 80
```
