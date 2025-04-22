#!/bin/bash

YAML_CONTENT=$(cat << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: configuration-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Vicheak/k8s_orchestration.git
    targetRevision: main
    path: test_pipeline/api
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - Validate=false
EOF
)

TMP_FILE=$(mktemp)
echo "$YAML_CONTENT" > "$TMP_FILE"

kubectl apply -f "$TMP_FILE"

rm "$TMP_FILE"