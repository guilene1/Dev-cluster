# Scenario 3: OOMKilled and Kubernetes Resource Limits

## Objective

Use Kubernetes evidence to distinguish memory pressure from an unsafe container resource limit.

## Trigger the Incident

Run this from the repository root against your own lab environment:

```bash
./scripts/chaos/shrink-limits.sh support-tickets
```

The script saves the current resources and applies a deliberately unsafe memory request and limit. Wait for restarts to appear before troubleshooting.

## Situation

The support tickets service is unstable. Backend pods restart repeatedly while some requests still succeed.

## Symptoms

- Backend pods restart repeatedly.
- Application stability degrades.

## What You Know

- Container restart counts are increasing.
- The problem began after a workload resource change.

## Start With the Symptom

1. Watch the backend pods. The newest one keeps restarting and ends up in `CrashLoopBackOff`:

```bash
kubectl get pods -n support-tickets -l app=support-tickets-backend -w
```

2. Check how much memory the healthy pods use:

```bash
kubectl top pods -n support-tickets
```

Record the restart timestamp, pod name, and the memory the healthy pods use. Confirm the exact `OOMKilled` reason with `kubectl describe` below.

## Troubleshooting

1. Identify the restarting pod.

```bash
kubectl get pods -n support-tickets -l app=support-tickets-backend
```

Expected output: the older pods stay Running, while the newest pod's `RESTARTS` count is greater than zero and keeps increasing.

2. Inspect the previous container termination.

```bash
kubectl describe pod <pod-name> -n support-tickets
```

Expected output: under **Last State**, the reason is `OOMKilled` and the exit code is `137`.

3. Compare the memory a healthy pod uses with the configured limit.

```bash
kubectl top pods -n support-tickets
kubectl get deployment support-tickets-backend -n support-tickets \
  -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

Expected output: healthy backend pods use about `16Mi`, but the Deployment now sets a `12Mi` memory limit. The new container exceeds that limit while starting, and Kubernetes terminates it.

4. Check the previous container logs for supporting evidence.

```bash
kubectl logs <pod-name> -n support-tickets --previous
```

Expected output: logs stop around the restart time and may not contain a graceful application error. `OOMKilled` in the pod state is the authoritative evidence.

## Important Clues

Look for `Reason: OOMKilled`. Compare observed memory consumption with `resources.requests.memory` and `resources.limits.memory`.

## Root Cause

Record the relationship between observed memory, the previous container state, and the configured limit before you apply the fix.

## Fix

Restore the known baseline, then use observed utilization to propose a justified long-term request and limit.

```bash
./scripts/chaos/shrink-limits.sh support-tickets --undo
kubectl rollout status deployment/support-tickets-backend -n support-tickets
```

Do not remove the limit or choose an arbitrary large value.

## Validation

Confirm pods remain Ready, restart counts stop increasing, memory stays below the limit, and requests succeed.

## DevOps Lesson

Resource limits must reflect measured workload behavior. Admission control can accept a value that is operationally unsafe.

## STAR Method

### Situation

Summarize the unstable workload.

### Task

Explain how you separated application, Kubernetes, and infrastructure causes.

### Action

Describe the memory, restart, previous-state, and resource comparison.

### Result

State how stability and memory headroom were verified.

## Natural Spoken Version

Use the matching example in [DevOps STAR Scenarios](../devops-star-scenarios.md#3-oomkilled) after completing the lab.

## Brief STAR Example

An internal backend repeatedly restarted after its memory limit was reduced to 12 MiB. My task was to distinguish an application failure from a Kubernetes resource problem. I correlated the restarts and the memory the healthy pods used with exit code 137 and `OOMKilled` in the pod state, then restored a measured memory limit. The restart loop stopped, pods remained Ready, and future resource values were based on observed usage.
