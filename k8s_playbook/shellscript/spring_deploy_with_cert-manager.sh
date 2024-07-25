#!/bin/bash
fullImageName=$1
YAML_CONTENT=$(cat << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spring-app
  template:
    metadata:
      labels:
        app: spring-app
    spec:
      containers:
        - name: spring-app
          image: ${fullImageName}
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: spring-volume
              mountPath: /workspace
      volumes:
        - name: spring-volume
          nfs:
            server: 10.104.0.2
            path: /opt/nfs/data/
---
apiVersion: v1
kind: Service
metadata:
  name: spring-service
spec:
  selector:
    app: spring-app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: ClusterIP      
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: spring-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    kubernetes.io/ingressClassName: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  tls:
  - hosts:
    - spring.cheakautomate.online
    secretName: spring-ingress-tls
  rules:
  - host: spring.cheakautomate.online
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: spring-service
            port:
              number: 8080
EOF
)

# Create a temporary file to store the Spring Application YAML
TMP_FILE=$(mktemp)
echo "$YAML_CONTENT" > "$TMP_FILE"

# Apply the Spring Application YAML
kubectl apply -f "$TMP_FILE"

# Clean up the temporary file
rm "$TMP_FILE"