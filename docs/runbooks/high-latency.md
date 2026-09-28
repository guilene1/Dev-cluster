# Runbook: High Latency

## Symptoms

- Users report slow page loads or slow API responses.
- Timing requests with `curl -w '%{time_total}'` shows responses climbing
  above 500ms-1s.

## Diagnostic commands

```bash
# Is it one pod or all pods? Check CPU/memory per pod
kubectl -n <namespace> top pods

# Are readiness probes still passing, or is the pod struggling that badly?
kubectl -n <namespace> get pods

# Is it the frontend, the backend, or one pod? Time each layer
curl -s -o /dev/null -w '%{time_total}s\n' https://<app>.$(cat .lab-domain)/
curl -s -o /dev/null -w '%{time_total}s\n' https://<app>.$(cat .lab-domain)/api/<endpoint>
kubectl -n <namespace> port-forward pod/<pod> 4000:4000   # then curl localhost:4000
```

Use the timings to decide whether time is spent in the network path, one
pod, or application code for a specific endpoint. In this scenario, look at what the request handler does
(for example, ecommerce's `checkout` endpoint calls a
simulated payment processor with a 150-350ms delay by design
-- see `apps/ecommerce/backend/src/routes.js`).

## Common root causes in this lab

- **Injected latency** via the chaos hook (`POST /api/chaos/latency`) --
  check `GET /api/chaos` on the pod to see current chaos state.
- **Real downstream slowness** -- a busy shared RDS instance, or simply
  too much traffic for the current replica count (see HPA in
  `apps/<app>/k8s/hpa-backend.yaml`).

## Fix

1. Check `GET https://<app>.$(cat .lab-domain)/api/chaos` first -- if a chaos hook is
   active, reset it:
   ```bash
   curl -X POST https://<app>.$(cat .lab-domain)/api/chaos/reset
   ```
2. If it's real load, confirm the HPA is scaling:
   ```bash
   kubectl -n <namespace> get hpa
   ```
   If it's pinned at `maxReplicas` and still slow, you're out of horizontal
   headroom -- either raise `maxReplicas` or investigate why each pod isn't
   handling more throughput (often a downstream bottleneck, not a CPU one).
3. If one endpoint is slow because of a specific query, that's a code/index
   fix, not an ops fix -- file it, don't just restart pods and hope.

## Prevention

- Record baseline response times for each app's main endpoints, so a
  latency creep is noticed before users report it.
- Agree on a specific threshold for "too slow" per endpoint, so "high
  latency" means something specific, not a guess.

## Reproduce this in the lab

```bash
scripts/chaos/inject-latency.sh <app> 3000   # 3s of added latency
```
