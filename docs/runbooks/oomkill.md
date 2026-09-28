# Runbook: OOMKilled

## Symptoms

- `kubectl get pods` shows a pod restarting with `Reason: OOMKilled` in
  `describe pod`, or `Last State: Terminated, Reason: OOMKilled`.
- Requests to that pod fail abruptly mid-response when it dies.

## Diagnostic commands

```bash
# Confirm OOMKilled specifically (vs. a crash for another reason)
kubectl -n <namespace> describe pod <pod> | grep -A5 "Last State"

# Current memory per pod, and the configured limit
kubectl -n <namespace> top pods
kubectl -n <namespace> get deployment <app>-backend \
  -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

`kubectl top` is a snapshot. Run it a few times (or with `watch`) to see a
trend.

## Common root causes in this lab

- **A resource limit reduced below measured workload requirements**, which
  causes Kubernetes to terminate the container during startup or requests.
- Every backend's container `resources.limits.memory` is set to `256Mi`
  (see `apps/<app>/k8s/deployment-backend.yaml`) -- deliberately low, so
  this is easy to trigger and observe in the lab. In a real service, this
  would represent a genuine memory leak or an underprovisioned limit for
  actual peak usage.

## Fix

1. If the lab limit was reduced, restore the saved request and limit:
   ```bash
   scripts/chaos/shrink-limits.sh <app> --undo
   ```
2. If it's a real leak, a restart is a temporary mitigation, not a fix --
   `kubectl -n <namespace> rollout restart deployment/<app>-backend` buys
   time while someone finds the leaking code path.
3. If usage is *legitimately* higher than the limit (not a leak, just
   underprovisioned), raise `resources.limits.memory` in the Deployment
   and redeploy.

## Prevention

- Set requests/limits based on observed steady-state usage plus headroom,
  not guesses -- watch `kubectl top pods` under realistic load before
  picking a number.
- Watch for memory *approaching* the limit, not just after the OOMKill
  already happened -- by then you've already dropped requests.

## Reproduce this in the lab

```bash
scripts/chaos/shrink-limits.sh <app>
# The script applies a deliberately unsafe 12Mi limit; watch:
kubectl -n <app> get pods -w
```
