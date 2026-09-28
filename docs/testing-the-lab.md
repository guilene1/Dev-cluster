# Testing the Five Incident Scenarios

This is a live-test checklist, not a claim that a test has run. Use a disposable lab cluster. Test one scenario at a time and recover it before continuing.

| Scenario | Trigger | Expected Kubernetes result | Expected external result | Recovery |
|---|---|---|---|---|
| Bad image | `./scripts/chaos/bad-deploy.sh banking banking-backend banking-backend` | New pods reach `ImagePullBackOff` | App keeps working on the old pods | `kubectl rollout undo deployment/banking-backend -n banking` |
| Bad ConfigMap | `./scripts/chaos/break-config.sh student-portal` | New pods fail probes and restart | App keeps working on the old pods | `./scripts/chaos/break-config.sh student-portal --undo` |
| OOMKilled | `./scripts/chaos/shrink-limits.sh support-tickets` | Previous state is `OOMKilled`, exit code 137 | App keeps working on the old pods | `./scripts/chaos/shrink-limits.sh support-tickets --undo` |
| Bad Ingress | `./scripts/chaos/break-ingress.sh food-delivery` | Pods stay Ready | External `/` returns 404 | `./scripts/chaos/break-ingress.sh food-delivery --undo` |
| High latency | `./scripts/chaos/inject-latency.sh ecommerce 3000` | Pods normally remain Ready | API responses take about 3 seconds | Reset each backend process with `./scripts/chaos/reset.sh ecommerce` or port-forward |

For every test, record trigger time, pod and Deployment state, external response, and recovery time. Follow the detailed commands in `docs/incident-scenarios/` and do not run database-destructive tests.
