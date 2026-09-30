# Architectural Integration Resolutions
### Core System Infrastructure Alignment Document

---

### Challenge A: ProtectSystem=strict and the EnvironmentFile
* **The Resolution:** All environment configuration targets have been anchored directly under `/opt/kijanikiosk/config/` rather than the system `/etc/` matrix. 
* **The Mechanics:** Because `ProtectSystem=strict` forces the core operating system paths (`/etc`, `/usr`, `/boot`) into an absolute read-only lock, storing credentials there would block application initialization. The path `/opt/` remains readable by standard service sandboxes, ensuring that the `EnvironmentFile` directive reads configuration variables smoothly without requiring explicit directory read exceptions.

---

### Challenge B: The Monitoring User and ACL Defaults
* **The Resolution:** The new metrics directory `/opt/kijanikiosk/health/` is configured with strict group-level access rules mapping ownership to `kk-logs:kijanikiosk` and permissions to `640`.
* **The Mechanics:** Because the provisioning script executes with root administrative clearance, the initial file generation bounds ownership to root. To allow Amina and automated monitoring telemetry daemons to scrape health metrics safely without using `sudo`, the script explicitly runs `chown` and `chmod 640` operations. This ensures that utility background processes can parse the metrics payload cleanly while blocking unprivileged global users.

---

### Challenge C: logrotate postrotate and PrivateTmp
* **The Resolution:** The postrotate block uses a non-breaking graceful system check wrapper: `systemctl try-restart kk-logs.service 2>/dev/null || true`.
* **The Mechanics:** Because our lightweight services are running on a standard Python micro-server chassis without a custom embedded `ExecReload=` directive, calling `systemctl reload` triggers a fatal runtime script crash. Utilizing `try-restart` flushes out stale file handles efficiently, and appending the error pipe suppression guarantees that the `PrivateTmp=true` namespace boundaries do not block standard log maintenance rotations.

---

### Challenge D: The Dirty VM and Package Holds
* **The Resolution:** The provisioning architecture utilizes a safe pre-check guard rule via `apt-mark unhold` followed by explicit package state syncing.
* **The Mechanics:** To satisfy the strict idempotency targets, the automation framework rejects blind downgrade loops or hard terminal execution failures. The script unholds the package tracking flags, invokes an update routine, and pins the required software baseline cleanly. This maintains an uncompromised supply-chain security posture, preventing configuration drift across long-term staging environments.
