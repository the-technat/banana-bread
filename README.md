# banana_bread

The last homelab I'll ever build

Based on <https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.25.0/>

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

1. Get your AWS account ID and replace mine with it in `aws-nuke.yml`
2. Get your workspace ID and replace mine in `.github/workflows/payload.json`
3. Configure a schedule, mine is ever day at 10:00 PM + on demand
4. Add some secrets to the Github Repo:

- `AWS_ACCESS_KEY_ID`: Either use the same Access key as for Terraform or generate a new one
- `AWS_SECRET_ACCESS_KEY`: Either use the same Access key as for Terraform or generate a new one
- `TFC_TOKEN`: Create a user-token in Terraform Cloud
