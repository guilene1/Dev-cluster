# ConfigMap Rollout Runbook

Use this runbook when new pods fail probes after a configuration rollout while older pods remain healthy. Start with unavailable replicas, restart counts, warning events, and pod logs. Then compare the live ConfigMap, pod environment, Deployment probes, and rollout history.

```bash
kubectl rollout status deployment/<app>-backend -n <app>
kubectl get pods -n <app>
kubectl describe pod <pod> -n <app>
kubectl logs <pod> -n <app>
kubectl describe configmap <app>-backend-config -n <app>
kubectl get deployment <app>-backend -n <app> -o yaml
kubectl rollout history deployment/<app>-backend -n <app>
```

For the lab port mismatch:

```bash
./scripts/chaos/break-config.sh <app> --undo
kubectl rollout status deployment/<app>-backend -n <app>
```

Confirm all pods are Ready, traffic succeeds, and restarts stop.
