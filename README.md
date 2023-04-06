# banana-bread

The last homelab I'll ever build

## Cluster

Some specialities on this setup:

- Only the EKS managed SG is used
- Cilium in ENI-integrartion mode with kube-proxy replacemement is used
- On cluster-level is designed fully-HA except the NAT gateway (only one for all AZs)

## Addons

The following addons are setup:

- [cilium](https://cilium.io): fully managing the network (ENI integration, kube-proxy replacement)
- [aws-load-balancer-controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/): Controller for provisioning Load Balancers in AWS
- [argocd](https://argoproj.github.io/cd): Ready to deploy GitOps based apps
- [cert-manager](https://cert-manager.io/): manage certificates in a k8s native way
- [aws-efs-csi-driver](https://aws-ia.github.io/terraform-aws-eks-blueprints/main/add-ons/aws-efs-csi-driver/): managed by eks-blueprints
- [aws-ebs-csi-driver]()
- [cluster-autoscaler](https://aws-ia.github.io/terraform-aws-eks-blueprints/main/add-ons/aws-efs-csi-driver/): managed by eks-blueprints
- [external-dns](https://aws-ia.github.io/terraform-aws-eks-blueprints/main/add-ons/external-dns/): managed by eks-blueprints

## To Do

Always let some room for improvements:

- [ ] Deploy keda autoscaler
- [ ] Deploy metrics-server
- [ ] Configure cluster-autoscaler to prefer ARM64 nodes (and taint the other ones)
- [ ] Cilium not working in any case (no free IPs errors)
- [ ] Argo CD provider not working  (only one resource works)

## Deployment

Since we have 100% Terraform, the easiest way to get this deployed is by creating a workspace in Terraform Cloud, adding a pair of AWS credentials and selecting the VCS-driven workflow pointing to this repository.

### Step-by-Step

Here's the detailed version on how to deploy:

1. Create an Account in the [Terraform Cloud](https://app.terraform.io)
2. Create an [AWS Account](https://aws.amazon.com)
3. Create a new IAM user, assign it the `AdministratorAccess` role and generate a pair of Access keys
4. Create a new Terraform Workspace, configure the VCS-driven workflow and add two environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
5. Start your first run (won't be done automatically)

## Destruction

I'm not a fan of keeping homelabs running all the time. Mainly because of cost. I'll only need it when I want to tinker a bit. So I've wrote a simple Github Actions pipeline that destroyes my entire homelab on a schedule.

If you want to use this, go ahead, there's some configuration required.

1. Configure a [schedule](./.github/workflows/destroy.yml), mine is ever day at 10:00 PM + on demand
2. Get your workspace ID and replace mine in [.github/workflows/payload.json](./.github/workflows/payload.json)
3. Creata a user-token in Terraform Cloud and add it to the Repository secrets as `TFC_TOKEN`
