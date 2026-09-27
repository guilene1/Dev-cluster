# Read-only identity, rendered by scripts/users.sh when run with --readonly:
#   USER_NAME=<name> envsubst '${USER_NAME}' < rbac/user-readonly.yaml.tpl | kubectl apply -f -
#
# Meant to be ONE identity shared by a whole class (50+ people): no sandbox
# namespace, no write access anywhere. It gets its permissions from the same
# group binding as every other user (rbac/cluster-access.yaml: cluster-wide
# `view` minus Secrets), so there is nothing to bind per identity.
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${USER_NAME}
  namespace: lab-users
  labels:
    sre-lab/user: ${USER_NAME}
    sre-lab/mode: readonly
---
# Revocable long-lived token: `users.sh remove` deletes this and it stops
# working immediately for everyone holding the file.
apiVersion: v1
kind: Secret
metadata:
  name: ${USER_NAME}-token
  namespace: lab-users
  labels:
    sre-lab/user: ${USER_NAME}
    sre-lab/mode: readonly
  annotations:
    kubernetes.io/service-account.name: ${USER_NAME}
type: kubernetes.io/service-account-token
