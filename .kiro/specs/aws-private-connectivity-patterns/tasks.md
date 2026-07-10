# Implementation Plan: AWS Private Connectivity Patterns Demo

## Overview

This plan implements a Terraform IaC demo comparing four AWS private connectivity patterns (VPC Peering, PrivateLink, VPC Lattice, Transit Gateway) across three accounts (shared-services, dev, sandbox). Implementation follows a phased approach: repository scaffolding → foundation modules → account roots → lab modules → documentation.

All code is Terraform HCL targeting AWS provider `~> 5.0` and Terraform `>= 1.5` in `ap-southeast-2`. Each account root is applied independently via `AWS_PROFILE` with manual `terraform output` handoffs between stacks — no `assume_role`.

**Implementation status:** Complete.

## Cross-Stack Handoff Quick Reference

| Lab | Consumer → Shared services | Shared services → Consumer | Apply order |
|-----|-----------------------------|---------------------------|-------------|
| VPC Peering | `peering_connection_id`, `vpc_cidr_block` | `shared_services_vpc_id`, `shared_services_account_id`, `alb_dns_name` | Consumer, then shared-services |
| PrivateLink | — | `endpoint_service_name` | Shared-services, then consumer |
| VPC Lattice | — | `lattice_service_network_arn`, `lattice_service_dns_name` | Shared-services, then consumer |
| Transit Gateway | `vpc_cidr_block`, `tgw_attachment_id` | `tgw_id` | Shared-services, then consumer, then shared-services |

## Notes

- Account profile for the service host: `shared-services` (avoids confusion with Terraform `provider "aws"` blocks)
- Lab modules use `deployment_side = "shared-services" | "consumer"`
- Module `shared-services-app` hosts the internal ALB and JSON API
- Transit Gateway requires a third shared-services apply with `consumer_tgw_attachment_id`
