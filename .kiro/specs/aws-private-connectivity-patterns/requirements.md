# Requirements Document

## Introduction

This document specifies requirements for a hands-on Terraform demo that compares four private AWS service connectivity patterns for cross-VPC and cross-account east-west traffic. A shared-services account hosts a simple HTTP API behind an internal ALB. Consumer accounts (dev, sandbox) reach that API using four isolated labs — VPC Peering, PrivateLink, VPC Lattice, and Transit Gateway — each enabled independently via boolean feature flags on both shared-services and consumer stacks. The demo targets presenters who deploy, test with curl from consumer Test EC2 instances via SSM Session Manager, and tear down manually. All infrastructure runs in ap-southeast-2 in a single region.

**Implementation status:** Specification complete; Terraform modules and account roots are not yet implemented in the repository.

## Glossary

- **Shared_Services_Account**: The AWS account hosting the internal ALB and HTTP API backend.
- **Consumer_Account**: An AWS account (dev or sandbox) that connects to the Shared_Services_Account API through one of the connectivity patterns.
- **Shared_Services_Stack**: The Terraform root configuration under `terraform/accounts/shared-services/`.
- **Consumer_Stack**: A Terraform root configuration under `terraform/accounts/dev/` or `terraform/accounts/sandbox/`.
- **VPC_Peering**: An AWS networking construct that creates a direct L3 route between two VPCs requiring non-overlapping CIDRs.
- **PrivateLink**: An AWS service that exposes a provider service via an NLB and VPC Endpoint Service, consumed through an Interface VPC Endpoint in the consumer VPC (L4).
- **VPC_Lattice**: An AWS application networking service providing L7 connectivity through a Lattice service, service network shared via RAM, and consumer VPC association.
- **Transit_Gateway**: An AWS network transit hub (L3) that both VPCs attach to, with route tables directing traffic between consumer and shared-services CIDRs.
- **Internal_ALB**: An Application Load Balancer with scheme set to internal, listening on HTTP port 80, not reachable from the public internet.
- **NLB**: A Network Load Balancer operating at L4, placed in front of the Internal_ALB for PrivateLink patterns.
- **VPC_Endpoint_Service**: An AWS PrivateLink construct in the shared-services account that exposes an NLB to consumer accounts.
- **Interface_VPC_Endpoint**: An elastic network interface in the consumer VPC that connects to a VPC_Endpoint_Service.
- **RAM**: AWS Resource Access Manager, used to share VPC_Lattice service networks and Transit Gateways across accounts.
- **Service_Network**: A VPC Lattice construct that groups services and is shared to consumer accounts via RAM.
- **SSM_Session_Manager**: AWS Systems Manager Session Manager, providing shell access to EC2 instances in private subnets without public IPs or SSH keys.
- **Feature_Flag**: A boolean Terraform variable (default false for labs) that enables or disables a specific connectivity lab in a stack.
- **Cross_Stack_Variable**: A value produced by `terraform output` in one account root and passed as a Terraform variable to another account root during a separate apply with a different `AWS_PROFILE`.
- **EARS**: Easy Approach to Requirements Syntax, a structured pattern for writing unambiguous requirements.
- **CIDR**: Classless Inter-Domain Routing notation for IP address ranges.
- **Test_EC2**: A t4g.nano EC2 instance in a private subnet reachable only via SSM_Session_Manager, used to run curl tests.
- **Terraform_Module**: A reusable Terraform configuration package located under `terraform/modules/`.
- **Account_Root**: A Terraform root configuration directory under `terraform/accounts/` representing one AWS account stack.

## Requirements

### Requirement 1: Shared Services Account Infrastructure

**User Story:** As a presenter, I want a shared-services account stack with an internal ALB serving a simple HTTP API, so that consumer accounts have a target service to connect to through each connectivity pattern.

#### Acceptance Criteria

1. WHEN the shared-services Account_Root is applied, THE Shared_Services_Stack SHALL create a VPC with CIDR 10.10.0.0/16, 2 private subnets across 2 availability zones in ap-southeast-2, DNS support enabled (`enableDnsSupport` and `enableDnsHostnames` both true), and SSM VPC endpoints for `ssm`, `ssmmessages`, and `ec2messages`.
2. WHEN the shared-services Account_Root is applied, THE Shared_Services_Stack SHALL create an Internal_ALB listening on HTTP port 80 with a target EC2 backend that returns a JSON response containing the fields `pattern`, `hostname`, `instance_id`, and `timestamp`.
3. THE Shared_Services_Stack SHALL set the `pattern` field from a `connectivity_pattern` input variable (for example `peering`, `privatelink`, `lattice`, `tgw`, or `shared-services` during foundation-only deploys).
4. WHEN the shared-services Account_Root is applied, THE Shared_Services_Stack SHALL output `vpc_id`, `vpc_cidr_block`, `account_id`, and `alb_dns_name` for use by consumer stacks and lab modules.
5. IF `enable_test_ec2` is true, THEN THE Shared_Services_Stack SHALL deploy a Test_EC2 instance in a private subnet reachable via SSM_Session_Manager.
6. THE Shared_Services_Stack SHALL tag all resources with default tags `Project` (set to the repository project name), `Account` (set to `shared-services`), and `ManagedBy` (set to `terraform`).
7. THE Shared_Services_Stack SHALL use the default AWS credential chain with `AWS_PROFILE` and SHALL NOT use `assume_role` provider configuration.
8. WHEN the shared-services Account_Root is applied, THE Shared_Services_Stack SHALL create no NAT Gateway and no Internet Gateway in the VPC.

### Requirement 2: Consumer Account Infrastructure

**User Story:** As a presenter, I want dev and sandbox consumer account stacks with isolated VPCs, so that each consumer can independently test connectivity patterns against the shared-services API.

#### Acceptance Criteria

1. WHEN the dev Account_Root is applied, THE Dev_Stack SHALL create a VPC with CIDR 10.20.0.0/16, at least 2 private subnets across distinct availability zones, `dns_support` and `dns_hostnames` enabled, no NAT Gateway, no Internet Gateway, and SSM VPC endpoints for `ssm`, `ssmmessages`, and `ec2messages`.
2. WHEN the sandbox Account_Root is applied, THE Sandbox_Stack SHALL create a VPC with CIDR 10.30.0.0/16, at least 2 private subnets across distinct availability zones, `dns_support` and `dns_hostnames` enabled, no NAT Gateway, no Internet Gateway, and SSM VPC endpoints for `ssm`, `ssmmessages`, and `ec2messages`.
3. THE Consumer_Stack SHALL declare required input variables `shared_services_account_id`, `shared_services_vpc_id`, and `shared_services_vpc_cidr` (default `10.10.0.0/16`) for cross-account lab configuration.
4. WHEN `enable_test_ec2` is true, THE Consumer_Stack SHALL deploy a t4g.nano Test_EC2 instance with no public IP in a private subnet, with an IAM instance profile granting SSM_Session_Manager access, reachable via `aws ssm start-session` within 120 seconds of reaching running state.
5. THE Consumer_Stack SHALL output `vpc_id`, `vpc_cidr_block`, `private_subnet_ids`, and `route_table_ids` as Terraform outputs for use by connectivity lab modules and shared-services-side applies.
6. THE Consumer_Stack SHALL tag all resources with `Project`, `Account`, and `ManagedBy` default tags.
7. THE Consumer_Stack SHALL use the default AWS credential chain with `AWS_PROFILE` and SHALL NOT use `assume_role` provider configuration.

### Requirement 3: VPC Peering Lab

**User Story:** As a presenter, I want a VPC Peering lab module that creates a cross-account peering connection with appropriate routes, so that I can demonstrate the simplest and cheapest L3 connectivity pattern.

#### Acceptance Criteria

1. WHEN `enable_lab_peering` is true in the Consumer_Stack, THE Consumer_Stack SHALL create a VPC peering connection request from the consumer VPC to the shared-services VPC specifying the shared-services account ID and shared-services VPC ID.
2. WHEN `enable_lab_peering` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL auto-accept the peering connection identified by `peering_connection_id` (supplied from the consumer stack output) and add route table entries directing consumer CIDR traffic through the peering connection.
3. WHEN `enable_lab_peering` is true in the Consumer_Stack, THE Consumer_Stack SHALL add route table entries on all private subnet route tables directing shared-services CIDR (`10.10.0.0/16`) traffic through the peering connection.
4. WHEN `enable_lab_peering` is true in the Consumer_Stack, THE Consumer_Stack SHALL configure security group rules on the Test_EC2 security group allowing outbound HTTP port 80 traffic to the shared-services CIDR.
5. WHEN `enable_lab_peering` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL configure security group rules on the Internal_ALB security group allowing inbound HTTP port 80 traffic from the consumer CIDR.
6. WHEN `enable_lab_peering` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL enable DNS resolution support on the peering connection so that the consumer can resolve the shared-services `alb_dns_name` to private IPs.
7. WHEN `enable_lab_peering` is true in the Consumer_Stack, THE Consumer_Stack SHALL output `peering_connection_id` for use by the shared-services stack apply.
8. WHEN `enable_lab_peering` is true AND `enable_test_ec2` is true, THE Test_EC2 SHALL receive an HTTP 200 response with a JSON body from the Internal_ALB at the shared-services `alb_dns_name` via curl over the peered route.

### Requirement 4: PrivateLink Lab

**User Story:** As a presenter, I want a PrivateLink lab module that exposes the shared-services ALB through an NLB and VPC Endpoint Service, so that I can demonstrate L4 private connectivity without VPC CIDR dependencies.

#### Acceptance Criteria

1. WHEN `enable_lab_privatelink` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create an NLB on TCP port 80 with the Internal_ALB IP addresses registered as targets in an IP-type target group.
2. WHEN `enable_lab_privatelink` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create a VPC_Endpoint_Service backed by the NLB with auto-acceptance enabled and the consumer account added as an allowed principal.
3. WHEN `enable_lab_privatelink` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL output `endpoint_service_name` for use by consumer stacks.
4. WHEN `enable_lab_privatelink` is true in the Consumer_Stack, THE Consumer_Stack SHALL create an Interface_VPC_Endpoint connected to the shared-services VPC_Endpoint_Service with private DNS enabled and a security group allowing outbound TCP port 80 to the endpoint.
5. WHEN `enable_lab_privatelink` is true in the Consumer_Stack, THE Consumer_Stack SHALL output `endpoint_dns_name` for use in Phase 3 curl tests.
6. WHEN `enable_lab_privatelink` is true AND `enable_test_ec2` is true, THE Test_EC2 SHALL receive an HTTP 200 response with a JSON body from the shared-services API via curl using the Interface_VPC_Endpoint DNS name.

### Requirement 5: VPC Lattice Lab

**User Story:** As a presenter, I want a VPC Lattice lab module that creates a Lattice service with an ALB target and shares the service network via RAM, so that I can demonstrate L7 application-layer connectivity.

#### Acceptance Criteria

1. WHEN `enable_lab_lattice` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create a VPC Lattice service with an HTTP listener on port 80 and a target group forwarding to the Internal_ALB on HTTP port 80.
2. WHEN `enable_lab_lattice` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create a Service_Network, associate the Lattice service with the Service_Network, and share the Service_Network to the consumer account via RAM.
3. WHEN `enable_lab_lattice` is true in the Consumer_Stack, THE Consumer_Stack SHALL associate the consumer VPC with the shared Service_Network.
4. WHEN `enable_lab_lattice` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL configure a VPC Lattice auth policy on the service or service network that allows the consumer account principal to invoke the service.
5. WHEN `enable_lab_lattice` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL output `lattice_service_dns_name` and `lattice_service_network_arn` for use by consumer stacks and test verification.
6. WHEN `enable_lab_lattice` is true AND `enable_test_ec2` is true, THE Test_EC2 SHALL receive an HTTP 200 response containing JSON with the connectivity pattern name when curling the VPC Lattice service DNS name.

### Requirement 6: Transit Gateway Lab

**User Story:** As a presenter, I want a Transit Gateway lab module that attaches both VPCs to a shared TGW with appropriate route tables, so that I can demonstrate hub-and-spoke L3 connectivity.

#### Acceptance Criteria

1. WHEN `enable_lab_tgw` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create a Transit_Gateway, attach the shared-services VPC to the Transit_Gateway, and share the Transit_Gateway to the consumer account via RAM.
2. WHEN `enable_lab_tgw` is true in the Consumer_Stack, THE Consumer_Stack SHALL attach the consumer VPC to the shared Transit_Gateway.
3. WHEN `enable_lab_tgw` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL create Transit_Gateway route table entries directing the consumer CIDR to the consumer VPC attachment and the shared-services CIDR to the shared-services VPC attachment.
4. WHEN `enable_lab_tgw` is true in the Consumer_Stack, THE Consumer_Stack SHALL add VPC route table entries directing shared-services CIDR (`10.10.0.0/16`) traffic through the Transit_Gateway attachment.
5. WHEN `enable_lab_tgw` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL add VPC route table entries directing consumer CIDR traffic through the Transit_Gateway attachment.
6. WHEN `enable_lab_tgw` is true in the Consumer_Stack, THE Consumer_Stack SHALL configure Test_EC2 security group rules allowing outbound HTTP port 80 to the shared-services CIDR; WHEN `enable_lab_tgw` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL configure Internal_ALB security group rules allowing inbound HTTP port 80 from the consumer CIDR.
7. WHEN `enable_lab_tgw` is true in the Shared_Services_Stack, THE Shared_Services_Stack SHALL output `tgw_id` for use by consumer stacks.
8. WHEN `enable_lab_tgw` is true AND `enable_test_ec2` is true, THE Test_EC2 SHALL receive an HTTP 200 response with a JSON body from the Internal_ALB at the shared-services `alb_dns_name` via curl over the Transit_Gateway route.

### Requirement 7: Feature Flag Isolation

**User Story:** As a presenter, I want boolean feature flags that enable labs independently with only one lab active per stack at a time, so that I can demonstrate each pattern in isolation without resource conflicts.

#### Acceptance Criteria

1. THE Shared_Services_Stack and each Consumer_Stack SHALL expose Feature_Flag variables `enable_lab_peering`, `enable_lab_privatelink`, `enable_lab_lattice`, and `enable_lab_tgw`, each as boolean type defaulting to false.
2. THE Shared_Services_Stack and each Consumer_Stack SHALL expose a Feature_Flag variable `enable_test_ec2` as boolean type defaulting to false, independent of the lab Feature_Flag mutual exclusion constraint.
3. IF more than one lab Feature_Flag is set to true in a single stack, THEN that stack SHALL fail at `terraform plan` with an error message indicating which lab flags are in conflict and that only one lab flag may be true at a time.
4. WHEN all lab Feature_Flags are false, THE stack SHALL deploy only the VPC and optional Test_EC2 without any connectivity lab resources.
5. WHEN exactly one lab Feature_Flag is true, THE stack SHALL deploy only the resources associated with that lab and no resources for the other three labs.
6. WHEN a lab is demonstrated, THE presenter SHALL set the same lab Feature_Flag to true in both the Shared_Services_Stack and the active Consumer_Stack before running connectivity tests.

### Requirement 8: Cross-Stack Coordination

**User Story:** As a presenter, I want documented cross-stack variable handoffs and apply order, so that I can deploy labs across three AWS accounts without `assume_role`.

#### Acceptance Criteria

1. THE Repository SHALL document that each account root is applied separately using `AWS_PROFILE` and that no Terraform `aws` provider `assume_role` blocks are used.
2. THE Walkthrough SHALL document the following Cross_Stack_Variable handoffs:

   | Lab | Shared services → Consumer | Consumer → Shared services | Apply order |
   |-----|--------------------|--------------------|-------------|
   | VPC Peering | `shared_services_vpc_id`, `shared_services_account_id`, `alb_dns_name` | `peering_connection_id`, `vpc_cidr_block` | Consumer first, then shared-services |
   | PrivateLink | `endpoint_service_name` | — | Shared-services first, then consumer |
   | VPC Lattice | `lattice_service_network_arn`, `lattice_service_dns_name` | — | Shared-services first, then consumer |
   | Transit Gateway | `tgw_id` | `vpc_cidr_block` (for shared-services TGW routes and SG rules) | Shared-services first, then consumer |

3. THE Shared_Services_Stack SHALL accept `consumer_account_id`, `consumer_vpc_cidr`, and `peering_connection_id` as input variables required only when the corresponding lab is enabled.
4. THE Consumer_Stack SHALL accept lab-specific shared-services outputs (`endpoint_service_name`, `lattice_service_network_arn`, `tgw_id`) as input variables required only when the corresponding lab is enabled.
5. THE Shared_Services_Stack SHALL set `connectivity_pattern` to the active lab name whenever a lab Feature_Flag is true.

### Requirement 9: Shared Terraform Modules

**User Story:** As a presenter, I want reusable Terraform modules under `terraform/modules/`, so that infrastructure patterns are consistent and maintainable across account stacks.

#### Acceptance Criteria

1. THE Repository SHALL contain a `vpc` Terraform_Module that creates a VPC with 2 private subnets across 2 availability zones, DNS support and DNS hostnames enabled, SSM VPC endpoints (`ssm`, `ssmmessages`, `ec2messages`), no NAT Gateway, and no Internet Gateway.
2. THE Repository SHALL contain a `shared-services-app` Terraform_Module that creates an Internal_ALB on HTTP port 80 with a target EC2 running a minimal web server returning a JSON response containing `pattern`, `hostname`, `instance_id`, and `timestamp`.
3. THE Repository SHALL contain a `test-ec2` Terraform_Module that creates a t4g.nano EC2 instance in a private subnet with SSM_Session_Manager access and no public IP.
4. THE Repository SHALL contain a `lab-peering` Terraform_Module invoked from the consumer side for peering requests, routes, and Test_EC2 security group rules, and from the shared-services side for peering acceptance, DNS options, routes, and ALB security group rules.
5. THE Repository SHALL contain a `lab-privatelink` Terraform_Module invoked from the shared-services side for NLB, VPC_Endpoint_Service, and allowed principals, and from the consumer side for Interface_VPC_Endpoint creation.
6. THE Repository SHALL contain a `lab-lattice` Terraform_Module invoked from the shared-services side for Lattice service, Service_Network, RAM share, and auth policy, and from the consumer side for VPC association.
7. THE Repository SHALL contain a `lab-tgw` Terraform_Module invoked from the shared-services side for Transit_Gateway creation, shared-services attachment, TGW routes, RAM share, and shared-services VPC routes, and from the consumer side for consumer attachment, VPC routes, and security group rules.
8. EACH Terraform_Module SHALL contain at minimum `main.tf`, `variables.tf`, and `outputs.tf` and SHALL be referenceable from Account_Root configurations using relative `source` paths.
9. WHEN `terraform validate` is run against any Terraform_Module with required variables provided, THE Terraform_Module SHALL pass validation without errors.
10. THE `vpc` Terraform_Module SHALL accept the VPC CIDR block as a required input variable so that account roots can specify distinct address ranges per stack.
11. EACH lab Terraform_Module SHALL use a `deployment_side` input variable with allowed values `shared-services` or `consumer` to select which resources are created in a given account root.

### Requirement 10: Phased Deployment Walkthrough

**User Story:** As a presenter, I want a `docs/walkthrough.md` documenting the phased deployment and curl-test steps, so that I can follow a repeatable demo sequence.

#### Acceptance Criteria

1. THE Walkthrough SHALL document Phase 1 steps with exact `terraform apply` commands for the shared-services Account_Root, a `terraform output` command to capture `alb_dns_name`, `vpc_id`, and `account_id`, and exact `terraform apply` commands for dev and sandbox Account_Roots with all lab Feature_Flags set to false and `enable_test_ec2=false`.
2. THE Walkthrough SHALL document Phase 2 steps for each of the four labs one at a time per consumer stack, showing exact `terraform apply` commands with the lab Feature_Flag set to true in both shared-services and consumer stacks, and listing all Cross_Stack_Variable handoffs from Requirement 8.
3. THE Walkthrough SHALL document Phase 3 steps with the exact `terraform apply` command setting `enable_test_ec2=true`, the AWS CLI command to connect via SSM_Session_Manager, and the exact curl command targeting the correct DNS name for each pattern (`alb_dns_name` for peering and TGW, `endpoint_dns_name` for PrivateLink, `lattice_service_dns_name` for VPC Lattice), along with the expected JSON response fields (`pattern`, `hostname`, `instance_id`, `timestamp`).
4. THE Walkthrough SHALL document teardown steps specifying `terraform destroy` commands in reverse order: disable labs and destroy consumer stacks (dev and sandbox) before destroying the shared-services stack.
5. THE Walkthrough SHALL include a prerequisites section listing required tools (Terraform >= 1.5, AWS CLI with Session Manager plugin), AWS account configuration (shared-services, dev, sandbox profiles), and the ap-southeast-2 region setting.

### Requirement 11: Terraform Configuration Standards

**User Story:** As a presenter, I want consistent Terraform configuration standards across all roots, so that the demo is professional and reproducible.

#### Acceptance Criteria

1. THE Account_Root SHALL contain a `versions.tf` file with a `required_providers` block specifying the AWS provider with a pessimistic version constraint (`~> 5.0`) and a `required_version` constraint of `>= 1.5` for the Terraform CLI.
2. THE Account_Root SHALL contain a `terraform.tfvars.example` file listing every declared variable with a placeholder or example value and a comment indicating whether the variable is required or optional.
3. WHEN `terraform validate` is run against any Account_Root after successful `terraform init`, THE Terraform_Configuration SHALL pass with zero errors.
4. THE Repository SHALL use ap-southeast-2 as the single deployment region for all stacks.
5. THE Account_Root SHALL declare the AWS provider region as a variable defaulting to ap-southeast-2, and SHALL NOT hard-code region values outside of variable defaults.
6. THE Repository SHALL contain a root-level `.gitignore` that excludes `.terraform/`, `*.tfstate`, `*.tfstate.*`, `.terraform.lock.hcl` local overrides, and `*.tfvars` files containing secrets.

### Requirement 12: Architecture Documentation

**User Story:** As a presenter, I want a `docs/architecture.md` with a pattern comparison table and decision matrix, so that I can explain cost tradeoffs and when to use each pattern.

#### Acceptance Criteria

1. THE Architecture_Document SHALL contain a comparison table listing VPC_Peering, PrivateLink, VPC_Lattice, and Transit_Gateway with columns for OSI layer, cost model, CIDR overlap support, cross-account complexity (rated Low/Medium/High), and scalability (rated Low/Medium/High).
2. THE Architecture_Document SHALL contain a decision matrix describing when to use each pattern based on use case categories (point-to-point, service exposure, application networking, hub-and-spoke), traffic volume thresholds, security requirements, and operational complexity.
3. THE Architecture_Document SHALL document the network topology with Shared Services VPC CIDR `10.10.0.0/16`, Dev consumer VPC CIDR `10.20.0.0/16`, and Sandbox consumer VPC CIDR `10.30.0.0/16`, showing the connectivity path for each pattern.
4. THE Architecture_Document SHALL document the cross-account deployment model (separate profiles, no `assume_role`, manual output handoff).

### Requirement 13: Intentional Exclusions

**User Story:** As a presenter, I want explicit documentation of out-of-scope items, so that audience members understand the boundaries of this demo.

#### Acceptance Criteria

1. THE Repository README.md SHALL contain an "Out of Scope" section listing the following items as intentionally excluded from v1: public internet path demo, HTTPS/ACM/TLS, NAT Gateway, multi-region deployment, automated test scripts, CI workflows, ECS/EKS, API Gateway, Cloud WAN, and PrivateLink resource endpoints without NLB.
2. THE Repository SHALL keep HTTP port 80 for all connectivity patterns without TLS termination in v1, and no Terraform configuration SHALL define HTTPS listeners, ACM certificates, or port 443 listeners.
3. THE Repository SHALL use EC2 backend instances for the shared-services API without container orchestration in v1, and no Terraform configuration SHALL define ECS clusters, ECS services, ECS task definitions, or EKS clusters.
4. THE Repository README.md "Out of Scope" section SHALL note that HTTPS/TLS termination and PrivateLink without NLB are candidates for v2 consideration.

### Requirement 14: Repository Structure

**User Story:** As a presenter, I want a well-organized repository structure, so that the codebase is navigable and each component is easy to find.

#### Acceptance Criteria

1. THE Repository SHALL organize Terraform modules under `terraform/modules/` with subdirectories `vpc`, `shared-services-app`, `test-ec2`, `lab-peering`, `lab-privatelink`, `lab-lattice`, and `lab-tgw`, where each subdirectory contains at minimum `main.tf`, `variables.tf`, and `outputs.tf`.
2. THE Repository SHALL organize account root configurations under `terraform/accounts/` with subdirectories `shared-services`, `dev`, and `sandbox`, where each subdirectory contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `terraform.tfvars.example`.
3. THE Repository SHALL contain `docs/architecture.md` and `docs/walkthrough.md` documentation files.
4. THE Repository SHALL contain a root-level README.md describing the project as a hands-on demo of private AWS service connectivity patterns across VPCs and accounts.
