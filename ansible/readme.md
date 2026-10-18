# Ansible — Kubernetes Cluster Setup

## Purpose

Use Ansible to configure Ubuntu EC2 instances and set up a self-managed Kubernetes cluster using kubeadm.

Ansible runs from the local machine and connects to the EC2 instances over SSH.

## Planned Workflow

1. Create the AWS infrastructure using Terraform.
2. Configure the Ansible inventory with the EC2 hosts, SSH user, and private key.
3. Test connectivity with Ansible.
4. Install and configure the container runtime and Kubernetes components.
5. Initialize the Kubernetes control plane.
6. Install the cluster network plugin (CNI).
7. Join the worker node.
8. Verify the cluster and deploy the existing Kubernetes manifests from `k8s/`.

## Decisions to Revisit After Infrastructure Creation

The following values are intentionally not finalized yet.

- [ ] **Inventory:** Add the actual EC2 IP addresses or hostnames.
- [ ] **SSH access:** Confirm the SSH username and private-key path.
- [ ] **Kubernetes version:** Choose a specific compatible version.
- [ ] **Container runtime:** Confirm the containerd version and installation source.
- [ ] **Pod CIDR:** Check for overlap with the AWS VPC and subnet CIDRs.
- [ ] **Control plane endpoint:** Use the appropriate private address for communication between cluster nodes.
- [ ] **CNI plugin:** Select a plugin compatible with the chosen Kubernetes version and Pod CIDR.
- [ ] **Security Groups:** Verify SSH access and the network rules required for Kubernetes.
- [ ] **Outbound connectivity:** Determine how nodes will download packages and container images without introducing unnecessary infrastructure costs.
- [ ] **Existing variables:** Review `group_vars/all.yml` and retain only the variables actually needed by the playbooks.

## Notes

- The cluster will be self-managed using kubeadm; Amazon EKS is not part of this plan.
- Existing Kubernetes manifests under `k8s/` should be reused and reviewed rather than recreated unnecessarily.
- Do not finalize infrastructure-dependent settings before the AWS resources and network ranges are known.
- Keep the setup simple and add Ansible configuration only when required by the next implementation step.
