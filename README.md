# ⚙️ Live Departures – Infrastructure


## 🌐 Live Demo

**Try the app: [https://live-departures.pages.dev/](https://live-departures.pages.dev/)**


<p align="center">
  <img src="demo1.gif" height="75%" alt="Departures View" />
  &nbsp;
  &nbsp;
  &nbsp;
  &nbsp;
  &nbsp;
  &nbsp;
  <img src="demo2.gif" height="75%" alt="Map View" />
</p>
<p align="center"><em>Departures (left) and map (right) views from the Live Departures PWA</em></p>

* 🖼️ **Frontend (PWA):** [github.com/lukasznidecki/live-departures](https://github.com/lukasznidecki/live-departures)  
* 🧪 **Backend API:** [github.com/lukasznidecki/live-departures-backend](https://github.com/lukasznidecki/live-departures-backend)

📌 **This repository contains all infrastructure code** for deploying the PWA and its  backend to a production-grade
Kubernetes environment using Terraform, Helm, ArgoCD, Cloudflare, and GCP services.

---

## 📌 Overview

This repository contains the **infrastructure as code** for deploying the Live Departures PWA and its Backend API
to a production-grade Kubernetes environment.

It demonstrates:

- **Terraform** for provisioning cloud resources
- **Helm** for Kubernetes deployments
- **ArgoCD** for GitOps continuous delivery
- **OIDC Authentication**
- **Secrets management** via Google Secret Manager
- **Monitoring & Logging** with Prometheus, Grafana, Loki
- **DNS & TLS** via Cloudflare
