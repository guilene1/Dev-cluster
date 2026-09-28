# Student Guide

This lab teaches a hands-on troubleshooting loop across Amazon EKS, ECR, ALB, Kubernetes, and application workloads. Amazon RDS PostgreSQL remains the application datastore, but database troubleshooting is not one of the five incidents.

## 1. Prepare and deploy

Complete the prerequisites and `scripts/setup.sh` workflow in the [README](../README.md#project-walkthrough). Never commit credentials.

```bash
kubectl get nodes
kubectl get deployments -A
kubectl get pods -A
```

Open all five applications and record a healthy baseline before you break anything: pod counts, restart counts, `kubectl top pods`, and response times from `curl`.

## 2. Where to find evidence

| Evidence | Command |
|---|---|
| Pods and workloads | `kubectl get pods,deployments,rs -n <app> -o wide` |
| Kubernetes warnings | `kubectl get events -n <app> --field-selector type=Warning --sort-by=.lastTimestamp` |
| Pod details and previous state | `kubectl describe pod -n <app> <pod>` |
| Application logs | `kubectl logs -n <app> deploy/<app>-backend` (add `--previous` for a crashed container) |
| CPU and memory | `kubectl top pods -n <app>` |
| Rollout history | `kubectl rollout history deployment/<app>-backend -n <app>` |
| Routing | `kubectl describe ingress -n <app>`, `kubectl get endpoints -n <app>` |
| External behavior | `curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" https://<app>.<domain>/` |
| AWS side | `aws elbv2 describe-target-health`, `aws ecr describe-images` |

## 3. Troubleshooting workflow

For every incident: start from the symptom, scope the affected service and time, investigate Kubernetes and AWS with a specific question, connect the evidence before changing anything, apply the documented recovery, then validate Kubernetes state, application behavior, and external traffic.

## 4. Five scenarios

| Scenario | First symptom | Investigation |
|---|---|---|
| [1. Bad Container Image](incident-scenarios/01-bad-container-image.md) | Desired replicas exceed updated replicas; image-pull events | Deployment, failed pod, events, ECR tag |
| [2. Bad ConfigMap](incident-scenarios/02-bad-configmap-rollout.md) | Unavailable replicas, climbing restarts, probe events | Logs, ConfigMap, probe ports |
| [3. OOMKilled](incident-scenarios/03-oomkilled-resource-limits.md) | Restarts and `OOMKilled` in the previous container state | Previous state and resource limits |
| [4. Bad Ingress](incident-scenarios/04-alb-ingress-routing.md) | Public URL returns 404 while pods are healthy | ALB, Ingress, Service, endpoints |
| [5. High Latency](incident-scenarios/05-high-application-latency.md) | Slow `curl` response times; pods look healthy | Timing per endpoint, workload metrics, logs, chaos state |

## 5. Chaos script quick reference

Run only one scenario at a time, confirm its symptom, and complete recovery before continuing.

| Scenario | Trigger | Recovery |
|---|---|---|
| Bad image | `./scripts/chaos/bad-deploy.sh banking banking-backend banking-backend` | `kubectl rollout undo deployment/banking-backend -n banking` |
| Bad ConfigMap | `./scripts/chaos/break-config.sh student-portal` | `./scripts/chaos/break-config.sh student-portal --undo` |
| OOMKilled | `./scripts/chaos/shrink-limits.sh support-tickets` | `./scripts/chaos/shrink-limits.sh support-tickets --undo` |
| Bad Ingress | `./scripts/chaos/break-ingress.sh food-delivery` | `./scripts/chaos/break-ingress.sh food-delivery --undo` |
| High latency | `./scripts/chaos/inject-latency.sh ecommerce 3000` | Reset every affected process with `./scripts/chaos/reset.sh ecommerce` or the port-forward method in the scenario guide |

If you are connected to a teammate's cluster with a read-only kubeconfig, the recovery commands will be denied. Investigate with `kubectl get`, `describe`, and `logs`, and state the root cause and the fix you would apply.

## 6. Evidence and teardown

Record the start time, first symptom, affected resources, key command output, root cause, recovery, external validation, and one prevention action. Follow the [README teardown instructions](../README.md#6-destroy-the-lab) when finished.
