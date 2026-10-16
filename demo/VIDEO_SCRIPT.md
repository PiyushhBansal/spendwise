# Demo video: recording script (target 12–15 min)

Record with QuickTime (File → New Screen Recording) or OBS. Save the file as `demo/spendwise-demo.mp4`.

GitHub rejects files over 100 MB. If your recording is bigger, either compress it:
`ffmpeg -i in.mov -vcodec libx264 -crf 28 -preset slow -acodec aac demo/spendwise-demo.mp4`
or upload it to a **GitHub Release** as an asset and link it from the README.

## Before you hit record
- [ ] `terraform apply` finished; `kubectl get nodes` shows nodes Ready
- [ ] ingress-nginx, kube-prometheus-stack and ArgoCD are installed; the `spendwise` app is Synced/Healthy
- [ ] Port-forwards are open in separate terminals: Prometheus `:9090`, Grafana `:3001`, ArgoCD `:8081`
- [ ] Run `./scripts/load-test.sh http://<elb-host> 300` a few minutes before, so Grafana has data
- [ ] Tabs open: GitHub repo, Actions, Packages, AWS Console (VPC, EKS), ArgoCD, Prometheus, Grafana, app
- [ ] A small, visible change is ready to commit (e.g. the subtitle text in `frontend/src/main.jsx`)

## 1. Slides (≈3 min)
Go through `demo/SpendWise-Presentation.pptx`: the problem, the tech stack, the architecture diagram, the CI/CD flow, the infrastructure, the K8s setup, observability, and what you learned.

## 2. Codebase (≈2 min)
- Folder structure (README "Repository layout")
- `backend/app/main.py`: the routes, `/health`, `/metrics` instrumentator
- `backend/tests/conftest.py`: SQLite override, so tests never touch prod
- `frontend/Dockerfile`: multi-stage build, unprivileged nginx
- `helm/spendwise/values.yaml`: the `tag:` that CI rewrites

## 3. CI/CD (≈3 min). Start this early: the pipeline takes a few minutes
- Make the small UI change, then `git commit -am "feat(ui): update tagline" && git push`
- Actions tab: watch `test`, then the two `image` jobs, then `deploy`
- Open the Trivy step log and explain the result (clean, or one CVE)
- Packages: both images, tagged with the commit SHA
- Show the bot's `ci: deploy <sha>` commit that changed `values.yaml`

## 4. Terraform (≈2 min)
- `cd terraform && terraform plan`: run it against the live infra (it should show no changes), or show a saved plan output
- AWS Console: VPC (2 public + 2 private subnets), EKS cluster `spendwise-eks` and its node group

## 5. ArgoCD (≈1 min)
- The `spendwise` app shows Synced and Healthy, and the revision matches the new commit SHA
- Explain the flow: CI commits the tag, ArgoCD notices, ArgoCD rolls it out

## 6. Kubernetes (≈1.5 min)
```bash
kubectl get pods -n spendwise -o wide
kubectl get svc -n spendwise
kubectl get ingress -n spendwise
helm list -n spendwise
kubectl describe pod -n spendwise -l app=spendwise-backend | grep Image:   # shows the SHA
```
- Open the app through the ELB hostname and show your UI change is live. Add, edit and delete an expense.

## 7. Prometheus (≈1 min)
- `curl http://<elb-host>/api/summary`, plus port-forward the backend and run `curl localhost:8000/metrics | head`
- Status → Targets: `serviceMonitor/spendwise/spendwise-backend/0` is **UP** (2/2)

## 8. Grafana (≈1 min)
- Dashboards → **SpendWise API**: request rate, p95 latency, error rate, status mix
- Run the load test live and watch the panels move

## 9. Wrap-up (≈30 s)
Summarise what you learned, then show `terraform destroy` (or say you will run it after grading).
