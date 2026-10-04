# Network Architecture and Routing Design

## 1. Conceptual Visual Architecture
Below is the structural breakdown of our isolated Virtual Network environment, segmented to maximize resource security.

```text
+-----------------------------------------------------------------------------------+

|  VIRTUAL NETWORK / VPC BOUNDARY (10.0.0.0/16)                                    |
|                                                                                   |
|   +------------------------------------+   +----------------------------------+   |
|   | PUBLIC SUBNET (10.0.1.0/24)        |   | PRIVATE SUBNET (10.0.2.0/24)     |   |
|   | (Internet Accessible)              |   | (Isolated Internal Network)      |   |
|   |                                    |   |                                  |   |
|   |  [ Public Load Balancer / Edge ]   |   |  [ Core Application Backend ]    |   |
|   |                 |                  |   |                 |                |   |
|   +-----------------|------------------+   +-----------------|----------------+   |
|                     |                                        |                    |
|                     v                                        v                    |
|             [ Route Table ]                          [ Route Table ]              |
|          Destination: 0.0.0.0/0                   Destination: 0.0.0.0/0          |
|          Target: INTERNET GATEWAY                 Target: NAT GATEWAY             |
|                     |                                        |                    |
+---------------------|----------------------------------------|--------------------+

                      |                                        |
                      v                                        v
             ( Public Internet ) <-----------------------------+
```

---

## 2. Network Segmentation Strategy

### Public Subnet (`10.0.1.0/24`)
* **Role:** Acts as our secure outer perimeter and entry point.
* **Contents:** Houses public-facing resources such as entry traffic load balancers or gateway routers.
* **Routing Logic:** This subnet is directly associated with a Route Table containing an active default route (`0.0.0.0/0`) pointed at a virtual **Internet Gateway**. This enables two-way traffic communications directly with users on the public web.

### Private Subnet (`10.0.2.0/24`)
* **Role:** Acts as our secure inner vault.
* **Contents:** Houses our core application components and transaction-processing logic.
* **Routing Logic:** This subnet is entirely isolated from direct public internet lookups. Its Route Table **explicitly lacks an Internet Gateway route**, blocking all incoming connections initiated from the outside world.

---

## 3. Outbound Internet Routing Logic (NAT Gateway)
To maintain security compliance, our private application components sometimes need to download patches or fetch remote configuration data from external servers. 

1. To allow safe outbound-only internet traffic, we deploy a **Network Address Translation (NAT) Gateway** directly inside our **Public Subnet**.
2. We configure the Private Subnet's Route Table to direct all internet-bound traffic (`0.0.0.0/0`) through this NAT Gateway.
3. **The Security Outcome:** Our backend components can successfully request information from the external internet, but external bad actors on the internet are completely physically blocked from initiating a direct connection inward to our private application components.
