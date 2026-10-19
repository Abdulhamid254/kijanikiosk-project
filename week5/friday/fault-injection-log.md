### Operational Stability Grid
# KijaniKiosk Payments Service: Fault Injection Log
*   **Scenario 1: Code Typo or Mismatched Manifest Elements**
    *   *Staging Fault Introduced:* Code formatting guidelines violated or script names altered.
    *   *Triggering Gate:* Lint Stage
    *   *Observed System Behaviour:* The pipeline stopped immediately; the construction and publishing tracks were abandoned.
    *   *Architectural Design Justification:* Code that violates baseline layout footprints must be arrested immediately before consuming secondary server compilation power.

*   **Scenario 2: Corrupted Code Compilation**
    *   *Staging Fault Introduced:* Source file structural assembly block broken.
    *   *Triggering Gate:* Build Stage
    *   *Observed System Behaviour:* The initial structural gate passed; the parallel tracking and publishing tracks were skipped.
    *   *Architectural Design Justification:* If the code cannot build into a runnable bundle, secondary automated logic testing or security scanning becomes impossible.

*   **Scenario 3: Broken Transaction Math Assertion**
    *   *Staging Fault Introduced:* Forced mathematical miscalculation failure.
    *   *Triggering Gate:* Parallel Verify Stage (Testing Track)
    *   *Observed System Behaviour:* The security track finished; the archiving and warehouse publishing tracks were skipped.
    *   *Architectural Design Justification:* Parallel paths maximize engineering feedback loops, but functional errors must block release packaging to protect backend account balances.

*   **Scenario 4: High-Severity Open-Source Dependency Vulnerability**
    *   *Staging Fault Introduced:* Vulnerable module declaration injected into manifest scripts.
    *   *Triggering Gate:* Parallel Verify Stage (Security Track)
    *   *Observed System Behaviour:* The logical test track finished; the archiving and warehouse publishing tracks were skipped.
    *   *Architectural Design Justification:* Incorporating an unvetted or high-risk component compromises platform integrity, triggering an absolute freeze on production-line staging.

*   **Scenario 5: Warehouse Repository Communication Failure**
    *   *Staging Fault Introduced:* Misconfigured repository network port assignment.
    *   *Triggering Gate:* Publish to Nexus Stage
    *   *Observed System Behaviour:* Compilation, testing, security, and local archiving finished; the network transmission aborted.
    *   *Architectural Design Justification:* The code asset is verified healthy and safely logged in regional build memory, but the pipeline stops to protect registry record stability.

### Verification Wrap-up
All simulated faults have been systematically reverted. The production branch infrastructure has safely completed its evaluation loop and returned to a verified green status.' > week5/friday/fault-injection-log.md