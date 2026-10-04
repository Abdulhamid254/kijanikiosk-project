# DevOps Delivery Notes

## The Three Ways Alignment

### 1. Flow (Accelerating Delivery)
To optimize flow and minimize work-in-progress (WIP), we leverage a structured Git branching strategy (`main` -> `develop` -> `feature/*`). By isolating documentation and architectural foundations inside small, digestible feature branches like `feature/starter-kit-files`, we avoid massive, high-risk code merges and keep the delivery pipeline moving smoothly.

### 2. Feedback (Right to Left)
Feedback loops are built directly into our collaboration engine. By executing a Pull Request (PR) from our feature branch into `develop`, we create a critical engineering checkpoint. Peer-review feedback at this stage ensures security profiles (IAM) and routing schemas (Networking) are validated before any infrastructure is provisioned.

### 3. Learning (Continuous Experimentation)
Our workflow prioritizes safety and learning. Changes are initially integrated and tested inside the isolated `develop` branch. Failures encountered here provide systemic learning opportunities without introducing risks or downtime to the production environment (`main`).
