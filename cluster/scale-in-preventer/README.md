# scale-in-preventer

The scale-in-preventer tries to solve the following problem:

Whenever a nodegroup is replaced in Terraform, a new one is first created, then the pod are moved and finally the old one is deleted.

During the creation of the new nodegroup, EKS markes them as not eligible for scale-in by the cluster-autoscaler, but as soon as the creation is done, they  are eligible for scale-in, which causes race-conditions with the movement of the pods. If due to an aggressive PDB or so the movement of the pods fails, the new nodes might run for more than 10m without any workload, which would cause the cluster-autoscaler to scale-in these nodes, resulting in unnecessary scale-in/out cycles. To prevent this, this folder contains a lambda that makes sure, newly nodegroups are prevent from scale-in as long as their old sibling is still waiting to be deleted. As soon as the old nodegroup is deleted, the new nodegroup should of course be eligible for scale-in.