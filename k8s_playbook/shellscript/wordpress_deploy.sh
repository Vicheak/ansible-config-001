#!/bin/bash

YAML_CONTENT=$(cat << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: wordpress-deploy
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "wordpress"
  MYSQL_DATABASE: "wordpress"
  MYSQL_PASSWORD: "wordpress"
  MYSQL_USER: "wordpress"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: wordpress-config
  namespace: wordpress-deploy
data:
  WORDPRESS_DB_HOST: mysql-svc
  WORDPRESS_DB_NAME: wordpress
  WORDPRESS_DB_PASSWORD: wordpress
  WORDPRESS_DB_USER: wordpress
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy
  namespace: wordpress-deploy
spec:
  selector:
    matchLabels:
      app: mysql-app
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql-app
    spec:
      nodeSelector:
        task: worker
      containers:
      - image: mysql
        name: mysql-cont
        ports:
        - containerPort: 3306
        envFrom: 
          - secretRef:
              name: mysql-secret
        volumeMounts:
          - name: mysql-storage
            mountPath: /var/lib/mysql
      volumes:
        - name: mysql-storage
          hostPath:
            path: /home/vicheak/mysql-data
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-svc
  namespace: wordpress-deploy
spec:
  selector:
    app: mysql-app
  ports:
    - port: 3306
      protocol: TCP
  type: NodePort
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mysql-ingress
  namespace: wordpress-deploy
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    kubernetes.io/ingressClassName: "nginx"
spec:
  tls:
  - hosts:
    - cms.cheakautomate.online
    secretName: mysql-ingress-tls
  rules:
  - host: cms.cheakautomate.online
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mysql-svc
            port:
              number: 3306
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-deploy
  namespace: wordpress-deploy
spec:
  selector:
    matchLabels:
      app: wordpress-app
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress-app
    spec:
      nodeSelector:
        task: cms-service
      containers:
      - image: wordpress
        name: wordpress-cont
        envFrom:
          - configMapRef: 
              name: wordpress-config
        ports:
          - containerPort: 80
        volumeMounts:
          - name: wordpress-storage
            mountPath: /var/www/html
      volumes:
        - name: wordpress-storage
          hostPath:
            path: /home/vicheak/wordpress-data
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-svc
  namespace: wordpress-deploy
spec:
  selector:
    app: wordpress-app
  ports:
    - port: 80
      protocol: TCP
  type: NodePort
)

TMP_FILE=$(mktemp)
echo "$YAML_CONTENT" > "$TMP_FILE"

kubectl apply -f "$TMP_FILE"

rm "$TMP_FILE"