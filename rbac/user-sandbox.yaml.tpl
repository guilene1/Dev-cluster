# Per-participant resources, rendered by scripts/users.sh with
#   USER_NAME=<name> envsubst '${USER_NAME}' < rbac/user-sandbox.yaml.tpl | kubectl apply -f -
# Not a plain .yaml on purpose: `kubectl apply -f rbac/` must never try to
# apply the unrendered ${USER_NAME} placeholders.
#
# Everything here is keyed off one name, so `users.sh remove` can undo all of it.
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${USER_NAME}
  namespace: lab-users
  labels:
    lab/user: ${USER_NAME}
---
# A long-lived, revocable token: deleting this Secret (or the ServiceAccount)
# invalidates it immediately. Chosen over `kubectl create token` because the
# recipients have no AWS access and can't refresh a short-lived one. The token
# stays in `lab-users`, where no participant can read Secrets.
apiVersion: v1
kind: Secret
metadata:
  name: ${USER_NAME}-token
  namespace: lab-users
  labels:
    lab/user: ${USER_NAME}
  annotations:
    kubernetes.io/service-account.name: ${USER_NAME}
type: kubernetes.io/service-account-token
---
apiVersion: v1
kind: Namespace
metadata:
  name: sandbox-${USER_NAME}
  labels:
    app.kubernetes.io/part-of: k8s-lab
    lab/user: ${USER_NAME}
    # `baseline` rejects privileged pods, hostPath/hostNetwork/hostPort and
    # added capabilities -- what a hostile or careless pod would need to reach
    # the node it runs on (and through it, the node's IAM role).
    pod-security.kubernetes.io/enforce: baseline
---
# Ceilings, not reservations: they cap what one person can consume so a full
# sandbox can't starve the five shared apps. Sized for ~5 small pods. Multiply
# by the number of participants when checking node capacity (see README).
apiVersion: v1
kind: ResourceQuota
metadata:
  name: sandbox-quota
  namespace: sandbox-${USER_NAME}
  labels:
    lab/user: ${USER_NAME}
spec:
  hard:
    requests.cpu: 250m
    requests.memory: 320Mi
    limits.cpu: 500m
    limits.memory: 640Mi
    pods: "5"
    services: "5"
    configmaps: "10"
    secrets: "10"
    count/deployments.apps: "10"
    count/jobs.batch: "10"
    # Anything that costs money or is reachable from outside the cluster is
    # capped at zero. A Service of type LoadBalancer would make the AWS Load
    # Balancer Controller create a real NLB; NodePort exposes node ports.
    services.loadbalancers: "0"
    services.nodeports: "0"
    persistentvolumeclaims: "0"
---
# Gives every container a request/limit so the quota above (which requires
# them) never rejects a plain `kubectl run`, and caps a single container.
apiVersion: v1
kind: LimitRange
metadata:
  name: sandbox-limits
  namespace: sandbox-${USER_NAME}
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 50m
        memory: 64Mi
      default:
        cpu: 100m
        memory: 128Mi
      max:
        cpu: 250m
        memory: 256Mi
      min:
        cpu: 10m
        memory: 8Mi
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sandbox-user
  namespace: sandbox-${USER_NAME}
subjects:
  - kind: ServiceAccount
    name: ${USER_NAME}
    namespace: lab-users
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: lab-sandbox-user
