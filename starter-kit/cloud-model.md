# Cloud Service Model Selection

## Decision: Platform as a Service (PaaS)
We have selected **Platform as a Service (PaaS)** (such as AWS Elastic Beanstalk, Azure App Services, or Google Cloud Run) as our foundational cloud service model.

### Architectural Justification
* **Operational Focus:** PaaS abstracts away runtime optimization, OS patching, and underlying hypervisor management. This shifts engineering effort away from undifferentiated heavy lifting, allowing 100% of our focus to go toward deploying KijaniKiosk applications.
* **Velocity vs. Control:** While Infrastructure as a Service (IaaS) provides low-level control, it introduces significant continuous maintenance overhead. Conversely, SaaS eliminates development flexibility. PaaS hits the ideal sweet spot: providing automated horizontal scaling and built-in deployment tooling out of the box.
