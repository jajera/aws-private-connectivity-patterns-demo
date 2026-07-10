# aws-private-connectivity-patterns-demo

Hands-on Terraform demo comparing five AWS private connectivity patterns for cross-VPC, cross-account east-west traffic:

- **VPC Peering** (L3)
- **PrivateLink** (L4)
- **VPC Lattice** (L7)
- **Transit Gateway** (L3 hub-and-spoke)
- **Cloud WAN** (L3 global network + segmentation)

Each pattern is a **standalone solution** under `terraform/patterns/<name>/` with its own state, VPCs, and resources. Pick one directory, deploy, test with `curl` via SSM, destroy — no lab-flag switching.

## Quick start

1. Configure AWS CLI profiles: `shared-services`, `dev` (Cloud WAN spans `ap-southeast-2`, `ap-southeast-6`, `ap-southeast-1`)
2. Follow [docs/walkthrough.md](docs/walkthrough.md) for the pattern you want (includes curl examples + diagrams)
3. Read [docs/architecture.md](docs/architecture.md) for topology and comparison
4. Diagrams: [docs/diagrams/](docs/diagrams/) (SVG + `.drawio`, official [AWS icons](https://jajera.github.io/aws-icons))

## Repository structure

```text
terraform/
├── patterns/
│   ├── peering/          # 10.10 ↔ 10.20
│   ├── privatelink/      # 10.11 ↔ 10.21
│   ├── lattice/          # 10.12 ↔ 10.22
│   ├── tgw/              # 10.13 ↔ 10.23
│   └── cloudwan/         # 10.14 ↔ 10.24 / 10.34
│       ├── shared-services/
│       └── consumer/
└── modules/
    ├── vpc/
    ├── shared-services-app/
    ├── test-ec2/
    └── {peering,privatelink,lattice,tgw,cloudwan}-{provider,consumer}/
```

Example:

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/privatelink/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

## Out of scope (v1)

- Public internet path demo (NAT is outbound-only)
- HTTPS / ACM / TLS
- Automated test scripts / CI
- ECS / EKS / API Gateway

## Requirements

- Terraform `>= 1.5`
- AWS provider `~> 5.0` (Cloud WAN roots pin `>= 6.0, < 7.0`)
- AWS CLI with Session Manager plugin
- Two AWS accounts (`shared-services`, `dev`)
