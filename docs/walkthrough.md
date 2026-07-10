# Walkthrough: Independent Pattern Demos

Each connectivity pattern is a **standalone solution** under `terraform/patterns/<pattern>/`.
No lab flags. No tearing down one pattern to try another (unless you want to save cost).

Diagrams use official [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) (browseable at [jajera.github.io/aws-icons](https://jajera.github.io/aws-icons)). Editable `.drawio` sources live in [`docs/diagrams/`](diagrams/).

## Verification Status

End-to-end `apply` + `destroy` validated in `ap-southeast-2`:

| Pattern | Apply | Destroy | Notes |
|---------|-------|---------|-------|
| PrivateLink | PASS | PASS | ALB/NLB ordering fix in provider module |
| VPC Lattice | PASS | PASS | Demo EC2 is x86/`t3` for SSM stability |
| VPC Peering | PASS | PASS | Accept + requester DNS follow-up apply |
| Transit Gateway | PASS | PASS | Consumer attach + shared-services route follow-up |
| Cloud WAN | PASS | PASS | 3 regions (SYD/NZ/SG), segment isolation verified via core-network routes |

| Pattern | Directory | Shared CIDR | Consumer CIDR |
|---------|-----------|-------------|---------------|
| VPC Peering | `patterns/peering` | `10.10.0.0/16` | `10.20.0.0/16` |
| PrivateLink | `patterns/privatelink` | `10.11.0.0/16` | `10.21.0.0/16` |
| VPC Lattice | `patterns/lattice` | `10.12.0.0/16` | `10.22.0.0/16` |
| Transit Gateway | `patterns/tgw` | `10.13.0.0/16` | `10.23.0.0/16` |
| Cloud WAN | `patterns/cloudwan` | `10.14.0.0/16` | `10.24.0.0/16`, `10.34.0.0/16` |

CIDRs differ so you *can* deploy more than one pattern at once. For cost, run **one pattern at a time** and destroy when done.

## Prerequisites

- AWS CLI profiles: `shared-services`, `dev`
- Region: `ap-southeast-2`
- Session Manager plugin installed
- Terraform `>= 1.5`

```bash
export AWS_REGION=ap-southeast-2
export DEV_ACCOUNT_ID=$(AWS_PROFILE=dev aws sts get-caller-identity --query Account --output text)
```

Optional: copy `docs/local.env.example` → `docs/local.env` and fill values as you go.

### What success looks like

Every pattern serves the same demo API. From the consumer test EC2:

```bash
curl -s http://<target-dns>/
```

Expected JSON (field values change per deploy; `pattern` identifies which lab you hit):

```json
{
  "pattern": "<privatelink|lattice|peering|tgw|cloudwan>",
  "hostname": "ip-10-x-x-x.ap-southeast-2.compute.internal",
  "instance_id": "i-...",
  "timestamp": "2026-07-11T05:12:34.567890Z"
}
```

| Pattern | `pattern` value | Typical curl target |
|---------|-----------------|---------------------|
| PrivateLink | `privatelink` | Interface endpoint DNS (`*.vpce.amazonaws.com`) |
| VPC Lattice | `lattice` | Lattice service DNS (`*.vpc-lattice-svcs.*.on.aws`) |
| VPC Peering | `peering` | Shared-services internal ALB DNS |
| Transit Gateway | `tgw` | Shared-services internal ALB DNS |
| Cloud WAN | `cloudwan` | Shared-services internal ALB DNS (policy-controlled by segment) |

Echo the `curl` command **before** `ssm start-session` — env vars do not carry into the SSM shell.

---

## PrivateLink (simplest 2-step)

Consumer reaches the shared API through an **interface VPC endpoint**. No CIDR routing between VPCs — only the published service.

![PrivateLink architecture](diagrams/privatelink.svg)

Editable source: [`privatelink.drawio`](diagrams/privatelink.drawio) (open in [diagrams.net](https://app.diagrams.net/))

### 1. Shared-services — PrivateLink

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/privatelink/shared-services init
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/privatelink/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

```bash
export ENDPOINT_SERVICE_NAME=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/privatelink/shared-services output -raw endpoint_service_name)
```

### 2. Consumer — PrivateLink

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/privatelink/consumer init
AWS_PROFILE=dev terraform -chdir=terraform/patterns/privatelink/consumer apply \
  -var="endpoint_service_name=$ENDPOINT_SERVICE_NAME"
```

### 3. Test — PrivateLink

```bash
export ENDPOINT_DNS_NAME=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/privatelink/consumer output -raw endpoint_dns_name)
export TEST_EC2_INSTANCE_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/privatelink/consumer output -raw test_ec2_instance_id)

echo "curl -s http://$ENDPOINT_DNS_NAME/"
AWS_PROFILE=dev aws ssm start-session --region "$AWS_REGION" --target "$TEST_EC2_INSTANCE_ID"
# paste the curl from the echo above
```

**Example** (endpoint DNS from a verified run; `hostname` / `instance_id` / `timestamp` change every deploy):

```text
$ curl -s http://vpce-06bcebf2e5a7d1937-nroe17eh.vpce-svc-0a06ca901427ac642.ap-southeast-2.vpce.amazonaws.com/
{
  "pattern": "privatelink",
  "hostname": "ip-10-11-x-x.ap-southeast-2.compute.internal",
  "instance_id": "i-...",
  "timestamp": "2026-07-11T04:18:02.112233Z"
}
```

### 4. Destroy (consumer first) — PrivateLink

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/privatelink/consumer destroy -auto-approve \
  -var="endpoint_service_name=$ENDPOINT_SERVICE_NAME"
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/privatelink/shared-services destroy -auto-approve \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

---

## VPC Lattice (2-step + RAM accept)

L7 service networking: shared-services publishes a Lattice service; the service network is shared to `dev` via **AWS RAM**.

![VPC Lattice architecture](diagrams/lattice.svg)

Editable source: [`lattice.drawio`](diagrams/lattice.drawio) (open in [diagrams.net](https://app.diagrams.net/))

### 1. Shared-services — Lattice

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services init
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

```bash
export LATTICE_SERVICE_NETWORK_ARN=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services output -raw lattice_service_network_arn)
export LATTICE_RESOURCE_SHARE_ARN=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services output -raw lattice_resource_share_arn)
export LATTICE_SERVICE_DNS_NAME=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services output -raw lattice_service_dns_name)
```

### 2. Consumer — Lattice

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/lattice/consumer init
AWS_PROFILE=dev terraform -chdir=terraform/patterns/lattice/consumer apply \
  -var="lattice_service_network_arn=$LATTICE_SERVICE_NETWORK_ARN" \
  -var="lattice_resource_share_arn=$LATTICE_RESOURCE_SHARE_ARN"
```

### 3. Test — Lattice

```bash
export TEST_EC2_INSTANCE_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/lattice/consumer output -raw test_ec2_instance_id)
echo "curl -s http://$LATTICE_SERVICE_DNS_NAME/"
AWS_PROFILE=dev aws ssm start-session --region "$AWS_REGION" --target "$TEST_EC2_INSTANCE_ID"
```

**Example** (service DNS from a verified run):

```text
$ curl -s http://apcp-lat-lat-service-0438cb27379999034.7d67968.vpc-lattice-svcs.ap-southeast-2.on.aws/
{
  "pattern": "lattice",
  "hostname": "ip-10-12-x-x.ap-southeast-2.compute.internal",
  "instance_id": "i-...",
  "timestamp": "2026-07-11T04:41:19.445566Z"
}
```

### 4. Destroy — Lattice

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/lattice/consumer destroy -auto-approve \
  -var="lattice_service_network_arn=$LATTICE_SERVICE_NETWORK_ARN" \
  -var="lattice_resource_share_arn=$LATTICE_RESOURCE_SHARE_ARN"
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/lattice/shared-services destroy -auto-approve \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

---

## VPC Peering (3 applies — accept + DNS)

Cross-account peering needs an accept step, then requester DNS so the consumer can resolve the shared ALB name.

![VPC Peering architecture](diagrams/peering.svg)

Editable source: [`peering.drawio`](diagrams/peering.drawio) (open in [diagrams.net](https://app.diagrams.net/))

### 1. Shared-services (VPC + app only) — Peering

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services init
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

```bash
export SHARED_SERVICES_ACCOUNT_ID=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services output -raw account_id)
export SHARED_SERVICES_VPC_ID=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services output -raw vpc_id)
export ALB_DNS_NAME=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services output -raw alb_dns_name)
```

### 2. Consumer (create peering request) — Peering

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer init
AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer apply \
  -var="shared_services_account_id=$SHARED_SERVICES_ACCOUNT_ID" \
  -var="shared_services_vpc_id=$SHARED_SERVICES_VPC_ID"
```

```bash
export PEERING_CONNECTION_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer output -raw peering_connection_id)
```

### 3. Shared-services (accept + routes + ALB SG) — Peering

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID" \
  -var="peering_connection_id=$PEERING_CONNECTION_ID"
```

### 4. Consumer (enable requester DNS) — Peering

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer apply \
  -var="shared_services_account_id=$SHARED_SERVICES_ACCOUNT_ID" \
  -var="shared_services_vpc_id=$SHARED_SERVICES_VPC_ID" \
  -var="enable_requester_dns=true"
```

### 5. Test — Peering

```bash
export TEST_EC2_INSTANCE_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer output -raw test_ec2_instance_id)
echo "curl -s http://$ALB_DNS_NAME/"
AWS_PROFILE=dev aws ssm start-session --region "$AWS_REGION" --target "$TEST_EC2_INSTANCE_ID"
```

**Example** (ALB DNS from a verified run):

```text
$ curl -s http://internal-apcp-peer-ss-app-alb-1211688068.ap-southeast-2.elb.amazonaws.com/
{
  "pattern": "peering",
  "hostname": "ip-10-10-x-x.ap-southeast-2.compute.internal",
  "instance_id": "i-...",
  "timestamp": "2026-07-11T05:02:11.998877Z"
}
```

### 6. Destroy — Peering

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/peering/consumer destroy -auto-approve \
  -var="shared_services_account_id=$SHARED_SERVICES_ACCOUNT_ID" \
  -var="shared_services_vpc_id=$SHARED_SERVICES_VPC_ID"
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/peering/shared-services destroy -auto-approve \
  -var="consumer_account_id=$DEV_ACCOUNT_ID" \
  -var="peering_connection_id=$PEERING_CONNECTION_ID"
```

---

## Transit Gateway (3 applies — attach + TGW routes)

Hub-and-spoke L3: shared-services owns the TGW (shared via RAM); consumer attaches; shared-services adds the return route.

![Transit Gateway architecture](diagrams/tgw.svg)

Editable source: [`tgw.drawio`](diagrams/tgw.drawio) (open in [diagrams.net](https://app.diagrams.net/))

### 1. Shared-services (TGW + share + local attachment) — TGW

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services init
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

```bash
export TGW_ID=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services output -raw tgw_id)
export TGW_RESOURCE_SHARE_ARN=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services output -raw tgw_resource_share_arn)
export ALB_DNS_NAME=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services output -raw alb_dns_name)
```

### 2. Consumer (accept RAM + attach) — TGW

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/tgw/consumer init
AWS_PROFILE=dev terraform -chdir=terraform/patterns/tgw/consumer apply \
  -var="tgw_id=$TGW_ID" \
  -var="tgw_resource_share_arn=$TGW_RESOURCE_SHARE_ARN"
```

```bash
export TGW_ATTACHMENT_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/tgw/consumer output -raw tgw_attachment_id)
```

### 3. Shared-services (associate consumer attachment + TGW route) — TGW

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID" \
  -var="consumer_tgw_attachment_id=$TGW_ATTACHMENT_ID"
```

### 4. Test — TGW

```bash
export TEST_EC2_INSTANCE_ID=$(AWS_PROFILE=dev terraform -chdir=terraform/patterns/tgw/consumer output -raw test_ec2_instance_id)
echo "curl -s http://$ALB_DNS_NAME/"
AWS_PROFILE=dev aws ssm start-session --region "$AWS_REGION" --target "$TEST_EC2_INSTANCE_ID"
```

**Example** (ALB DNS from a verified run):

```text
$ curl -s http://internal-apcp-tgw-ss-app-alb-160178374.ap-southeast-2.elb.amazonaws.com/
{
  "pattern": "tgw",
  "hostname": "ip-10-13-x-x.ap-southeast-2.compute.internal",
  "instance_id": "i-...",
  "timestamp": "2026-07-11T05:28:44.001122Z"
}
```

### 5. Destroy — TGW

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/tgw/consumer destroy -auto-approve \
  -var="tgw_id=$TGW_ID" \
  -var="tgw_resource_share_arn=$TGW_RESOURCE_SHARE_ARN"
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/tgw/shared-services destroy -auto-approve \
  -var="consumer_account_id=$DEV_ACCOUNT_ID" \
  -var="consumer_tgw_attachment_id=$TGW_ATTACHMENT_ID"
```

---

## Cloud WAN (3 regions, segment isolation)

Global L3 hub with explicit segmentation:

- **shared** segment in `ap-southeast-2` (shared-services VPC + app ALB)
- **workloads** segment in `ap-southeast-6` (allowed to reach shared)
- **sandbox** segment in `ap-southeast-1` (isolated from shared/workloads)

![Cloud WAN architecture](diagrams/cloudwan.svg)

Editable source: [`cloudwan.drawio`](diagrams/cloudwan.drawio) (open in [diagrams.net](https://app.diagrams.net/))

### 1. Shared-services (global network + core network + RAM share) — Cloud WAN

```bash
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services init -upgrade
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services apply \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

```bash
export CWAN_CORE_NETWORK_ID=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services output -raw core_network_id)
export CWAN_CORE_NETWORK_ARN=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services output -raw core_network_arn)
export CWAN_RESOURCE_SHARE_ARN=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services output -raw core_network_resource_share_arn)
export ALB_DNS_NAME=$(AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services output -raw alb_dns_name)
```

### 2. Consumer (accept RAM + attach NZ + SG VPCs) — Cloud WAN

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/cloudwan/consumer init -upgrade
AWS_PROFILE=dev terraform -chdir=terraform/patterns/cloudwan/consumer apply \
  -var="core_network_id=$CWAN_CORE_NETWORK_ID" \
  -var="core_network_arn=$CWAN_CORE_NETWORK_ARN" \
  -var="core_network_resource_share_arn=$CWAN_RESOURCE_SHARE_ARN"
```

### 3. Test (policy-level pass/fail, account-independent) — Cloud WAN

The following checks verify intended segmentation directly from Cloud WAN routing state:

```bash
# workloads segment can see shared CIDR
AWS_PROFILE=shared-services aws networkmanager list-core-network-routing-information \
  --region ap-southeast-2 \
  --core-network-id "$CWAN_CORE_NETWORK_ID" \
  --segment-name workloads \
  --edge-location ap-southeast-6 \
  --query "CoreNetworkRoutingInformation[?Prefix=='10.14.0.0/16']"

# sandbox segment cannot see shared CIDR (must return [])
AWS_PROFILE=shared-services aws networkmanager list-core-network-routing-information \
  --region ap-southeast-2 \
  --core-network-id "$CWAN_CORE_NETWORK_ID" \
  --segment-name sandbox \
  --edge-location ap-southeast-1 \
  --query "CoreNetworkRoutingInformation[?Prefix=='10.14.0.0/16']"
```

### 4. Destroy (consumer first) — Cloud WAN

```bash
AWS_PROFILE=dev terraform -chdir=terraform/patterns/cloudwan/consumer destroy -auto-approve \
  -var="core_network_id=$CWAN_CORE_NETWORK_ID" \
  -var="core_network_arn=$CWAN_CORE_NETWORK_ARN" \
  -var="core_network_resource_share_arn=$CWAN_RESOURCE_SHARE_ARN"
AWS_PROFILE=shared-services terraform -chdir=terraform/patterns/cloudwan/shared-services destroy -auto-approve \
  -var="consumer_account_id=$DEV_ACCOUNT_ID"
```

---

## Notes

- Always destroy **consumer before shared-services** (PrivateLink endpoint before endpoint service; Lattice VPC association before service network).
- SSM: for single-region patterns use `--region ap-southeast-2`; for Cloud WAN use the instance region (`ap-southeast-6` workloads, `ap-southeast-1` sandbox).
- Demo EC2 instances use **x86_64 AL2023 + `t3.nano`**.
- If you interrupt Terraform mid-run and later hit a local state lock error, stop stale Terraform processes and re-run the same command:

```bash
pgrep -af "terraform.*patterns/<pattern>"   # inspect
pkill -f "terraform.*patterns/<pattern>"    # stop stale run you own
```

- If a resource was interrupted and shows as tainted/replacement in a later plan, continue with `apply` and let Terraform reconcile, then proceed with the normal flow.
