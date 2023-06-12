# Cluster

Some specialities on this setup:

- Only the EKS managed SG is used
- Cilium in overlay mode with kube-proxy replacemement is used 
  - sometimes Cilium is also used in ENI mode or cni-chaining, depending on what we want to test
- On cluster-level everything is designed fully-HA except the NAT gateway (only one for all AZs)
- no IPv6 (just confuses us when testing)

## To Do & Issues

Always let some room for improvements:

- [ ] Deploy keda autoscaler
- [ ] Deploy ebs-csi-controller
- [ ] Configure IPv6 

## Addon Rules

Some rules when deploying addons:
- as idempotent as possible
- tolerate ARM nodes when possible
- use IRSA where possible
- AWS addons are deployed into the `aws` namespace
- Set securityContext explicitly whenever possible to the most restrictive
- if it makes sense, set resource limits/requests

## Deployment

Since we have 100% Terraform, the easiest way to get this deployed is by creating a workspace in Terraform Cloud, adding a pair of AWS credentials and selecting the VCS-driven workflow pointing to this repository.

### Step-by-Step

Here's the detailed version on how to deploy:

1. Create an Account in the [Terraform Cloud](https://app.terraform.io)
2. Create an [AWS Account](https://aws.amazon.com)
3. Create a Route53 DNS Zone and replace my `dns_zone` var in `locals.tf`
4. Create a new IAM user, assign it the `AdministratorAccess` role and generate a pair of Access keys
5. Create a new Terraform Workspace, configure the VCS-driven workflow and add two environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
6. Start your first run (won't be done automatically)

## Destruction

I'm not a fan of keeping homelabs running all the time. Mainly because of cost. I'll only need it when I want to tinker a bit. So I've wrote a simple Github Actions pipeline that destroyes my entire homelab on a schedule.

If you want to use this, go ahead, there's some configuration required.

1. Configure a [schedule](./.github/workflows/destroy.yml), mine is ever day at 10:00 PM + on demand
2. Get your workspace ID and replace mine in [.github/workflows/payload.json](./.github/workflows/payload.json)
3. Creata a user-token in Terraform Cloud and add it to the Repository secrets as `TFC_TOKEN`