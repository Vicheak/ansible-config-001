#!/bin/bash

fullImageName=$1
YAML_CONTENT=$(cat << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portfolio-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: portfolio-app
  template:
    metadata:
      labels:
        app: portfolio-app
    spec:
      containers:
        - name: portfolio-app
          image: ${fullImageName}
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: portfolio-service
spec:
  selector:
    app: portfolio-app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: ClusterIP      
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portfolio-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    kubernetes.io/ingressClassName: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  tls:
  - hosts:
    - portfolio.cheakautomate.online
    secretName: portfolio-ingress-tls
  rules:
  - host: portfolio.cheakautomate.online
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: portfolio-service
            port:
              number: 8080
EOF
)

TMP_FILE=$(mktemp)
echo "$YAML_CONTENT" > "$TMP_FILE"

kubectl apply -f "$TMP_FILE"

rm "$TMP_FILE"