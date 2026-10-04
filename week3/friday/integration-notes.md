# Engineering Integration Notes: Production Infrastructure Alignment
**Prepared for:** Nia, Director of Operations  
**Target:** Dedicated Production Node Deployment (Payments Migration Baseline)

This document analyses the technical conflicts encountered while composing the KijaniKiosk security baseline and details the architectural choices implemented to achieve a coherent, non-breaking, production-grade system.

---

### Challenge A: ProtectSystem=strict and the EnvironmentFile

*   **The Conflict:** Enabling `ProtectSystem=strict` within systemd unit files forces standard runtime operating system structures—such as `/etc`, `/usr`, and `/boot`—into an absolute, immutable read-only mounting state. If the target application environment configuration variables or cryptographic credentials reside within standard locations like `/etc/kijanikiosk/`, the service process sandbox blocks its own initialization sequences, triggering immediate startup lifecycle failures.
*   **Options Considered:**
    1.  *Option 1:* Downgrade isolation parameters to `ProtectSystem=full` or `ProtectSystem=true` to allow local file system modifications or lower read-restriction limits.
    2.  *Option 2:* Maintain the strict sandboxing blueprint and declare explicit directory exception paths via `ReadWritePaths=` or `ReadOnlyPaths=`.
    3.  *Option 3:* Realignment of the deployment tree to isolate active secrets under an uncompromised path outside of standard system spaces.
*   **Selected Choice & Rationale:** *Option 3*. All target initialization variables were anchored explicitly within `/opt/kijanikiosk/config/payments-api.env`. Because `/opt/` (Optional Software Packages) remains readable by application processes under standard systemd strict parameters, this removes configuration visibility friction while preserving absolute security shielding across the core host directories.

---

### Challenge B: The Monitoring User and ACL Defaults

*   **The Conflict:** The automated health check loop (Phase 8) generates metrics tracking logs directly within the newly provisioned directory `/opt/kijanikiosk/health/`. Because the master provisioning automation script executes with root user authority, newly generated files inherently fall under root-owned security policies. However, the external monitoring engine, background telemetry probes, and Amina's regular administrative user identity require visibility into these files without invoking `sudo` privileges.
*   **Options Considered:**
    1.  *Option 1:* Open directory visibility constraints globally to `777` or file visibility to `666` so any host identity can scrape data.
    2.  *Option 2:* Append standard default POSIX file system access lists (`setfacl -d`) to force automatic inheritance down to all nested metrics strings.
    3.  *Option 3:* Execute explicit, deterministic post-generation identity transfers (`chown`/`chmod`) directly within the pipeline.
*   **Selected Choice & Rationale:** *Option 3 combined with group confinement*. The directory and nested JSON logs are forcefully adjusted via `chown kk-logs:kijanikiosk` and restricted to `chmod 640`. This enables Amina and authorized monitoring daemons (which inherit the shared `kijanikiosk` system group token) to safely parse the health status payload without broad world visibility or relying on bloated root escalation layers.

---

### Challenge C: logrotate postrotate and PrivateTmp

*   **The Conflict:** The `logrotate` background utility executes as a detached system process under root permissions via systemic cron management schedules. When it finishes truncating application logs inside `/opt/kijanikiosk/shared/logs/`, it triggers a `postrotate` script to signal background daemons to drop dead file handles. However, because our service layers run as lightweight Python micro-servers without custom embedded signal parsing routines, executing standard commands like `systemctl reload` triggers immediate automation crashes. Furthermore, `PrivateTmp=true` isolates process space loops, meaning standard external pipe hooks fail to intersect safely.
*   **Options Considered:**
    1.  *Option 1:* Completely drop the `PrivateTmp=true` switch from the systemd definition file to restore global temporary file visibility.
    2.  *Option 2:* Implement a hard operational server restart via `systemctl restart` directly during the rotation process.
    3.  *Option 3:* Utilize a safe, non-breaking graceful state check routine: `systemctl try-restart kk-logs.service 2>/dev/null || true`.
*   **Selected Choice & Rationale:** *Option 3*. Utilizing `try-restart` drops and re-initializes file tracking lines cleanly only if the service is already running. Suppressing standard error outputs avoids runtime workflow halts, ensuring that strict namespace isolation parameters remain active without breaking routine host maintenance operations.

---

### Challenge D: The Dirty VM and Package Holds

*   **The Conflict:** Running a provisioning automation framework against a dirty, non-clean environment introduces "configuration drift" bugs. If the target node has gone through manual lab iterations, core system tools like `curl` may have been pinned via unmanaged administrative hold directives (`apt-mark hold curl`). Attempting an automated installation or dependency check while hidden package holds exist causes apt tools to fail, throwing errors or blocking security patches.
*   **Options Considered:**
    1.  *Option 1:* Fail loudly. Stop the script immediately using `exit 1` when an unexpected hold is detected and request manual intervention.
    2.  *Option 2:* Ignore the environment states entirely, run standard installations, and allow background processes to suppress errors blindly.
    3.  *Option 3:* Clear existing tracking overrides via automated pre-checks and apply consistent version locking parameters.
*   **Selected Choice & Rationale:** *Option 3*. The script explicitly runs `sudo apt-mark unhold curl || true` at the beginning of Phase 4 before executing the system synchronization logic. This ensures that the installation layer possesses a predictable baseline workspace to apply compliance updates, preventing dirty legacy states from blocking deployment.
