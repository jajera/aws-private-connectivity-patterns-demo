# Architecture: AWS Private Connectivity Patterns Demo

## Overview

Five **independent** Terraform solutions compare private cross-account connectivity patterns. Each pattern under `terraform/patterns/<name>/` has its own state, VPC pair, app, and test EC2 — no shared lab flags and no tear-down-to-switch workflow.

| Pattern | OSI | Shared CIDR | Consumer CIDR | Project prefix |
|---------|-----|-------------|---------------|----------------|
| VPC Peering | L3 | `10.10.0.0/16` | `10.20.0.0/16` | `apcp-peer` |
| PrivateLink | L4 | `10.11.0.0/16` | `10.21.0.0/16` | `apcp-pl` |
| VPC Lattice | L7 | `10.12.0.0/16` | `10.22.0.0/16` | `apcp-lat` |
| Transit Gateway | L3 hub | `10.13.0.0/16` | `10.23.0.0/16` | `apcp-tgw` |
| Cloud WAN | L3 global hub | `10.14.0.0/16` | `10.24.0.0/16`, `10.34.0.0/16` | `apcp-cwan` |

Accounts: **shared-services** (provider) and **dev** (consumer). Most patterns run in **ap-southeast-2**; Cloud WAN spans **ap-southeast-2 / ap-southeast-6 / ap-southeast-1**. HTTP only (port 80). Workloads in private subnets; NAT for outbound; SSM for admin access.

Diagrams use official [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) ([browse](https://jajera.github.io/aws-icons)). Sources: [`docs/diagrams/*.drawio`](diagrams/).

## Connectivity Paths

### VPC Peering (L3)

![VPC Peering](diagrams/peering.svg)

### PrivateLink (L4)

![PrivateLink](diagrams/privatelink.svg)

### VPC Lattice (L7)

![VPC Lattice](diagrams/lattice.svg)

### Transit Gateway (L3 hub-and-spoke)

![Transit Gateway](diagrams/tgw.svg)

### Cloud WAN (L3 global network + segments)

![Cloud WAN](diagrams/cloudwan.svg)

Cloud WAN pattern uses segment isolation: `shared` can be shared to `workloads`, while `sandbox` remains isolated.

## Apply Order (per pattern)

| Pattern | Steps |
|---------|-------|
| PrivateLink | shared-services → consumer |
| Lattice | shared-services → consumer (RAM accept in module) |
| Peering | shared-services → consumer → shared-services (accept) → consumer (DNS) |
| TGW | shared-services → consumer → shared-services (attachment routes) |
| Cloud WAN | shared-services (global/core/RAM) → consumer (accept + attachments) |

No `assume_role`. Cross-stack values pass via `terraform output` → `-var`.

## Repository Layout

```text
terraform/
├── patterns/
│   ├── peering/{shared-services,consumer}/
│   ├── privatelink/{shared-services,consumer}/
│   ├── lattice/{shared-services,consumer}/
│   ├── tgw/{shared-services,consumer}/
│   └── cloudwan/{shared-services,consumer}/
└── modules/
    ├── vpc/
    ├── shared-services-app/
    ├── test-ec2/
    ├── peering-{provider,consumer}/
    ├── privatelink-{provider,consumer}/
    ├── lattice-{provider,consumer}/
    ├── tgw-{provider,consumer}/
    └── cloudwan-{provider,consumer}/
```

Provider/consumer modules are **side-specific** (no `deployment_side` switches).

## Pattern Comparison

| Pattern | Cost Model | CIDR Overlap | Best For |
|---------|------------|--------------|----------|
| VPC Peering | Free same-region data | No | Point-to-point, few VPCs |
| PrivateLink | NLB + endpoint + data | Yes | Service exposure, SaaS |
| VPC Lattice | Service + data | Yes | L7 routing, auth policies |
| Transit Gateway | TGW + attachment + data | No | Many VPCs, hub routing |
| Cloud WAN | Core network + edge + attachment + data | No | Multi-region global routing + segmentation |

## ADRs

**ADR-1: NLB in front of ALB for PrivateLink** — Endpoint services require an NLB; TG type `alb`.

**ADR-2: RAM for Lattice and TGW** — Shared via AWS RAM; consumer accepts with idempotent `local-exec`.

**ADR-3: Separate pattern roots** — Each pattern owns state and CIDRs; no mutual-exclusion flags.

**ADR-4: SSM + NAT** — SSM for shell; single NAT per VPC for outbound bootstrap.

**ADR-5: No assume_role** — Manual output → var handoffs between account roots.

**ADR-6: Side-specific modules** — `*-provider` / `*-consumer` instead of `deployment_side` conditionals.
