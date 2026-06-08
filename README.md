# 🏗️ Production-Grade EKS GitOps Pipeline

A declarative, highly available, and self-healing infrastructure and application deployment pipeline utilizing **Terraform**, **Amazon EKS (v1.30)**, and **ArgoCD** to implement true GitOps practices. This project demonstrates automated cloud infrastructure provisioning, fine-grained IAM security mappings, and dynamic AWS Application Load Balancer (ALB) orchestration.

---

## 📐 Architecture Overview

The system architecture spans a fully isolated network topology, a managed Kubernetes control plane, and a declarative continuous delivery loop:

* **The Network Boundary (AWS VPC):** Provisions a highly available multi-AZ layout consisting of isolated Public Subnets (hosting the Internet Gateway, NAT Gateways, and the Application Load Balancer) and Private Subnets (housing the EKS worker nodes to ensure zero direct public exposure).
* **Compute & Governance (Amazon EKS):** Manages worker node scaling via an EKS Managed Node Group (`t3.medium` instances). Fine-grained access control is established via an IAM OIDC Provider using IAM Roles for Service Accounts (IRSA).
* **GitOps Continuous Delivery (ArgoCD):** Maintains a real-time synchronization loop with this repository, monitoring specific application paths to enforce cluster state declaration, drift detection, and automated self-healing.
* **Ingress Automation:** Utilizes the AWS Load Balancer Controller to dynamically provision, configure, and tear down physical AWS Application Load Balancers based purely on cluster Ingress state changes.

---

## 🛠️ Tech Stack & Tools

| Layer | Technologies Used |
| :--- | :--- |
| **Cloud Provider** | AWS (EKS, VPC, EC2, IAM, ELB) |
| **Infrastructure-as-Code** | Terraform (v1.x+) |
| **Container Orchestration** | Kubernetes (v1.30), Helm |
| **Continuous Delivery (GitOps)** | ArgoCD |
| **Application Layer** | Nginx (High Availability Deployment) |
| **Local Environment** | WSL2 (Ubuntu), AWS CLI, Kubectl |

---

## 📂 Repository Structure
## 📂 Repository Structure

The project separates initial bootstrapping, core infrastructure definitions, and Kubernetes application manifests:

* **`bootstrap/`**: The initial Terraform layer containing `main.tf` and `outputs.tf` to establish baseline tracking or remote state storage prerequisites before building out the primary resource layout.
* **`infrastructure/`**: The primary Infrastructure-as-Code block that handles the actual multi-AZ network configurations, EKS cluster plane, IAM role bindings (IRSA), and provisions the ArgoCD Helm delivery engine.
* **`apps/`**: The application runtime tier where the individual microservices (like our Nginx deployment, internal cluster service, and external AWS ALB Ingress rules) are managed purely via GitOps declarations.
```text
├── bootstrap/               # Terraform Bootstrap Layer
│   ├── main.tf              # Entry point for bootstrap initializations
│   └── outputs.tf           # Exposed outputs from the bootstrap configuration
├── apps/                    # GitOps Application Manifests
│   └── sample-web-app/
│       └── app-manifests.yaml # Unified Deployment, Service, & Ingress Manifests
└── infrastructure/          # Core Infrastructure-as-Code Layer (IaC)
    ├── provider.tf          # Terraform AWS & Kubernetes Providers
    ├── vpc.tf               # Core AWS VPC Network Infrastructure
    ├── eks.tf               # Amazon EKS Cluster Definition
    ├── iam.tf               # Scoped IAM Policies & IRSA OIDC Module Mappings
    └── argocd.tf            # Helm Release Definition for the GitOps Engine



    ├── eks.tf               # Amazon EKS Cluster Definition
    ├── iam.tf               # Scoped IAM Policies & IRSA OIDC Module Mappings
    └── argocd.tf            # Helm Release Definition for the GitOps Engine

---

## 🔧 Engineering Challenges & Resolutions

During the engineering lifecycle of this pipeline, several production-grade architectural hurdles were identified, isolated, and engineered through:

### 1. Webhook Race Conditions During Core Bootstrap
* **Challenge:** During a single unified `terraform apply`, the ArgoCD Helm installation failed due to an unavailable mutating admission webhook endpoint (`mservice.elbv2.k8s.aws`) managed by the concurrent AWS Load Balancer Controller bootstrap.
* **Resolution:** Isolated the core cloud infrastructure dependency cycle. Utilized localized resource target isolation (`terraform apply -target`) to allow the Kubernetes API control plane and the network controller endpoints to stabilize and accept validation configurations cleanly before establishing the secondary application delivery loops.

### 2. Fine-Grained IAM Policy Boundaries (`ModifyRule` 403 AccessDenied)
* **Challenge:** The application controller failed to bind healthy target pod IPs to the active Application Load Balancer listener rules, throwing an automated `FailedDeployModel` warning because the identity-based security policies restricted the `elasticloadbalancing:ModifyRule` action on the target resource.
* **Resolution:** Audited cluster event streams natively via `kubectl describe` and refactored the infrastructure IAM policy tracking block to explicitly declare `elasticloadbalancing:ModifyRule` capabilities, allowing safe runtime execution under the principle of least privilege without expanding global resource scopes.

---

## 📈 Verification & Deployment Proof

### 1. ArgoCD GitOps Live State Tree
The application tier successfully hooks into ArgoCD, rendering a completely healthy declarative management graph containing the cluster service, deployment replicaset, and two active worker pods:

![ArgoCD Active Deployment Tree](docs/images/argocd-tree.png)

### 2. Live Public AWS Endpoint
The physical internet-facing AWS Application Load Balancer successfully accepts public traffic and proxies it smoothly into our private subnet pod nodes, resolving to the live Nginx landing page:

![AWS ALB Nginx Landing Page](docs/images/nginx-success.png)