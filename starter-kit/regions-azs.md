
## 1. Region Selection
We designate a primary geographic deployment region (e.g., **AWS eu-west-1 Ireland** or **us-east-1 N. Virginia**) selected against three production pillars:
* **Compliance & Sovereignty:** Aligning directly with localized regional data privacy constraints (e.g., GDPR).
* **Latency Mitigation:** Ensuring minimal round-trip time (RTT) for our target application consumers.
* **Feature Completeness:** Ensuring the chosen region natively supports our entire target PaaS and security stack.

## 2. Multi-Availability-Zone (Multi-AZ) Resilience
To meet high availability targets, our infrastructure is spread across **at least two isolated Availability Zones (AZs)**.
* **Fault Isolation:** Each AZ represents a physically separate data center facility with discrete power grids, cooling infrastructure, and network feeds.
* **Blast Radius Mitigation:** If an unexpected disaster knocks out AZ-A, an automated application load balancer routes incoming traffic instantly to the redundant instances standing by in AZ-B. This design completely removes single points of failure (SPOF).
