# banana-bread

The last homelab I'll ever build

## What is this?

A pile of Terraform code that deploys an AWS EKS cluster with a bunch of addons, ready to tinker with.

Why use EKS?
> It just works + saves you time when you want to tinker something other than cluster creation ;)

Why not a Terraform module?
> Something has to change always + no need for multiple clusters to be staged with

## Overview

We have two folders:
- cluster: contains the Terraform code + addons
- apps: contains app definitons and manifests, uses the app-of-apps pattern from Argo CD

## Cluster

Some specialities on this setup:

- Only the EKS managed SG is used for Control plane + Nodes
- Everything is encrypted using Customer-managed KMS keys
- Cilium in ENI mode with kube-proxy replacemement is used 
  - sometimes Cilium is also used in overlay mode or cni-chaining, depending on what I want to test
- On cluster-level everything is designed fully-HA except the NAT gateway (only one for all AZs)
  - Addons aren't HA though (but most could be made HA easily by increasing the number of replicas)
- no IPv6 (just confuses us when testing)

### Addons

Some design principles when deploying addons:
- as idempotent as possible
- tolerate ARM nodes when possible
- use IRSA where possible
- AWS addons are deployed into the `aws` namespace
- Set securityContext explicitly whenever possible to the most restrictive
- if it makes sense, set resource limits/requests
- Make sure Admisssion Controllers run in hostNetwork (so that overlay networking is possible)

### Terraform pipeline

Since we have 100% Terraform, the easiest way to get this deployed is by creating a workspace in Terraform Cloud, adding a pair of AWS credentials and selecting the VCS-driven workflow pointing to this repository.

#### Step-by-Step

Here are the steps required to get this deployed:

1. Create an Account in the [Terraform Cloud](https://app.terraform.io)
2. Create an [AWS Account](https://aws.amazon.com)
4. Create a new IAM user, assign it the `AdministratorAccess` role and generate a pair of Access keys
5. Create a new Terraform Workspace, configure the VCS-driven workflow and add two environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
6. Adjust `cluster/locals.tf` according your preferences / environment
7. Start your first run (won't be done automatically)
8. Add the NS records for the DNS zone to where they belong (required in order for Web UIs to work)


#### IAM Workflow

There's an IAM role called `EKSClusterAdmin` that is allowed to do anything in the cluster, manage all related AWS resources and so on. To assume this role, add your principal to the `cluster_admins` list in [locals.tf](cluster/locals.tf).

#### Destruction

I'm not a fan of keeping homelabs running all the time. Mainly because of cost. I'll only need it when I want to tinker a bit. So I've wrote a simple Github Actions pipeline that destroyes my entire homelab on a schedule.

If you want to use this, go ahead, there's some configuration required.

1. Configure a [schedule](./.github/workflows/destroy.yml), mine is ever day at 10:00 PM + on demand
2. Get your workspace ID and replace mine in [.github/workflows/payload.json](./.github/workflows/payload.json)
3. Creata a user-token in Terraform Cloud and add it to the Repository secrets as `TFC_TOKEN`