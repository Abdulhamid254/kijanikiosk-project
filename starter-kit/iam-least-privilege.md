# IAM Least Privilege Policy Design

## Application Task Context
Our application framework includes a background module tasked with executing transactional processing. To fulfill its role, this component requires specific, isolated access to our infrastructure storage system to complete two tasks:
1. **Read** application processing configuration templates.
2. **Write** new transactional confirmation data images into a dedicated cloud storage directory named `kijaniosk-application-assets`.

## Platform-Agnostic Access Policy Design
Since our workflow targets basic security principles, we define our access control rules using standard logical conditions rather than platform-specific code. This policy will be attached directly to the application's system identity profile.

### Rule 1: Data Object Interactions
* **Target Storage Unit:** `kijaniosk-application-assets/` (and all sub-directories/contents)
* **Permitted Operations:** `ReadObject` (Download/View), `WriteObject` (Upload/Create)
* **Access Decision:** ALLOW

### Rule 2: Storage Unit Verification
* **Target Storage Unit:** `kijaniosk-application-assets` (The root directory only)
* **Permitted Operations:** `ListContents` (View folder index names)
* **Access Decision:** ALLOW

---

## Security Design Justification

### 1. Enforcement of Least Privilege
The application component is explicitly restricted to only reading and writing files. It completely lacks administrative permissions. For example, it cannot delete the storage directory entirely, nor can it modify the access settings or look at other project folders. If a software bug or vulnerability is discovered in this application component, the blast radius is strictly locked down to this single folder.

### 2. Elimination of Broad Permissions (No Wildcards)
We have avoided the security risk of using an open master rule (such as an administrative `Allow All` rule). The identity cannot see, browse, or touch any other databases, servers, or components running within our cloud network environment. This ensures strict isolation across our infrastructure estate.
