# Demo video: recording script (target 12–15 min)

Record with QuickTime (File → New Screen Recording) or OBS. Save the file as `demo/spendwise-demo.mp4`.

GitHub rejects files over 100 MB. If your recording is bigger, either compress it:
`ffmpeg -i in.mov -vcodec libx264 -crf 28 -preset slow -acodec aac demo/spendwise-demo.mp4`
or upload it to a **GitHub Release** as an asset and link it from the README.

The platform runs on a **local Kubernetes cluster (kind) provisioned by Terraform**. The AWS VPC + EKS Terraform is written and validated, but the AWS account could not be activated in time, so the video shows that code and explains the blocker honestly (≈30 s).

## Before you hit record
- [ ] Docker Desktop has 8 GB of memory; `kubectl get pods -A` shows everything Running
- [ ] The ArgoCD app `spendwise` is Synced/Healthy; http://localhost shows the app
- [ ] Port-forwards are open in separate terminals:
  - `kubectl port-forward -n argocd svc/argocd-server 8081:80`
  - `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`
  - `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80`
- [ ] Run `./scripts/load-test.sh http://localhost 300` a few minutes before, so Grafana has data
- [ ] Browser tabs open: GitHub repo, Actions, Packages, ArgoCD (localhost:8081), Prometheus (localhost:9090), Grafana (localhost:3001, admin / spendwise-admin), app (localhost)
- [ ] A small visible change is ready (e.g. the tagline in `frontend/src/main.jsx`)

## 1. Slides (≈3 min)
Go through `demo/SpendWise-Presentation.pptx`: the problem, the stack, the architecture, CI/CD, DevSecOps, Terraform, Kubernetes, observability, and what you learned.

## 2. Codebase (≈2 min)
- Folder structure (README "Repository layout")
- `backend/app/main.py`: the routes, `/health`, `/metrics`
- `backend/tests/conftest.py`: SQLite override, so tests never touch prod
- `backend/Dockerfile` and `frontend/Dockerfile`: multi-stage builds, non-root
- `helm/spendwise/values.yaml`: the `tag:` that CI rewrites

## 3. CI/CD (≈3 min). Start this early: the pipeline takes a few minutes
- Make the UI change, then `git commit -am "feat(ui): update tagline" && git push`
- Actions tab: watch `test`, then the two `image` jobs, then `deploy`
- Open the earlier **failed** run and show Trivy blocking 7 HIGH CVEs, then the green run with 0. Explain CVE-2025-62727 in one sentence.
- Packages: both images, tagged with the commit SHA
- Show the bot commit `ci: deploy <sha> …` that changed `values.yaml`

## 4. Terraform (≈2.5 min)
**AWS target (≈30 s):**
- Open `terraform/main.tf`: VPC with 2 public + 2 private subnets, EKS with a managed node group
- `cd terraform && terraform validate`, which prints "Success"
- Say: *"The AWS account is still pending activation, so EC2 returns OptInRequired. The code is ready to apply the moment it activates."*

**Local platform (≈2 min):**
- Open `terraform/local/main.tf`: the kind cluster, ingress-nginx, metrics-server, kube-prometheus-stack, ArgoCD
- `cd terraform/local && terraform plan`, which shows the managed infrastructure ("No changes" once it's applied)
- `terraform state list` shows the 5 resources Terraform owns
- `docker ps` shows the `spendwise-control-plane` node container

## 5. ArgoCD (≈1 min)
- At localhost:8081, the `spendwise` app is **Synced / Healthy**, and its revision matches the bot's commit
- Explain the loop: CI commits the tag, ArgoCD notices within about 60 s, ArgoCD rolls it out
- Click the app tree: Deployments, then ReplicaSets, then Pods

## 6. Kubernetes (≈1.5 min)
```bash
kubectl get pods -n spendwise -o wide
kubectl get svc,ingress,hpa -n spendwise
helm list -A
kubectl describe pod -n spendwise -l app=spendwise-backend | grep Image:   # shows the SHA
```
- Open http://localhost: your UI change from step 3 is live. Add, edit and delete an expense.

## 7. Prometheus (≈1 min)
- `curl -s http://localhost/api/summary`, plus port-forward the backend and run `curl localhost:8000/metrics | head`
- At localhost:9090 → Status → Targets: `serviceMonitor/spendwise/spendwise-backend/0` is **UP** (2/2)

## 8. Grafana (≈1 min)
- localhost:3001 → Dashboards → **SpendWise API**: request rate, p95 latency, error rate, status mix
- Run `./scripts/load-test.sh http://localhost 100` live and watch the panels move

## 9. Wrap-up (≈30 s)
Summarise what you learned, then run `terraform destroy` in `terraform/local`, which removes the whole platform in one command.
