## 🎯 Objective

Demonstrate an **Internal Azure Container App** running in a private network (VNet-integrated), receiving external traffic through an **Azure load-balancing service that supports session affinity**, such as **Azure Application Gateway** or **Azure Front Door**.
The demo should highlight:

* Difference between **built-in ACA sticky sessions** and **load-balancer-level affinity**
* Secure routing via **private endpoint**
* Visibility into which replica served which request
  (via the existing `/whoami` Spring Boot endpoint)

---

## 🧩 Project Architecture Overview

```
[ Client / Internet ]
        │
        ▼
[ Azure Front Door / Application Gateway (Public IP) ]
        │
        ▼
[ Private Endpoint or Internal Load Balancer ]
        │
        ▼
[ ACA Environment (Internal Ingress) ]
        │
        ▼
[ Spring Boot /whoami app ]
```

---

## 👥 Collaboration Plan

### **You (Lead / Architecture & Integration)**

Focus on network design, ACA configuration, and validation.

| Area                          | Deliverables                                                                                                                                                |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Architecture Design**       | High-level diagram of the setup (Front Door → Private ACA). Clarify which LB service to use (e.g., Application Gateway for sticky sessions).                |
| **Infrastructure Deployment** | Azure CLI/Bicep scripts for: <br> - VNet + Subnets<br> - ACA Environment (internal mode)<br> - Container App using GHCR image<br> - Private DNS Zone + Link |
| **Ingress & Egress Controls** | Configure ACA ingress = internal; validate access from load balancer subnet only.                                                                           |
| **Affinity Verification**     | Update `/whoami` endpoint to log client IP + headers (e.g., `X-Forwarded-For`) for tracing.                                                                 |
| **Demo Narrative**            | Write the step-by-step explanation to show the difference between ACA sticky sessions and load-balancer affinity.                                           |

---

### **Collaborator (Networking / App Gateway & Validation Lead)**

Responsible for front-end routing, affinity config, and testing user experience.

| Area                            | Deliverables                                                                                                                                                                                     |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Load-Balancing Layer Setup**  | Provision and configure **Azure Application Gateway** (Standard V2 or WAF V2) in the same VNet.<br> - Backend pool = private ACA FQDN or IP<br> - Health probe = `/actuator/health` or `/whoami` |
| **Session Affinity Config**     | Enable **Cookie-based Affinity** (`Application Gateway cookie`). Verify behaviour with and without it.                                                                                           |
| **DNS / Endpoint Exposure**     | Create a public DNS record or use `*.azurefd.net` endpoint; ensure only LB has access to ACA internal endpoint.                                                                                  |
| **Testing & Logging**           | Use curl, Postman, or browser DevTools to demonstrate: <br> - With affinity: same ACA replica<br> - Without affinity: round-robin behaviour<br> - Observe `ApplicationGatewayAffinity` cookie    |
| **Documentation & Screenshots** | Capture Azure Portal configuration, network flow diagram, cookie headers, and session stickiness results.                                                                                        |

---

## 🧠 Optional Advanced Contributions

| Topic                            | Description                                                                                                   | Owner        |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------ |
| **Azure Front Door alternative** | Show how global load balancing (Front Door) handles stickiness (front-door-managed cookies) for public entry. | Collaborator |
| **Observability**                | Configure Log Analytics / Application Insights to trace requests by client IP and replica hostname.           | You          |
| **Automation (Phase 2)**         | Convert the manual setup into an IaC template (Bicep or Terraform).                                           | Both         |

---

