 # codimite_assesment

# Terraform & Infrastructure-as-Code (IaC)
- find the terraform files inside the ../../iac folder
- I've Created a github actions workflow to automate the terraform actions on ./.github/workflows/tf-actions.yml
- run terraform validation upon PR is created for correctness of changes and configurations
-  in above workflow file we'll be initializing the tf backend and validate tf state and plan and upon user approval we'll deploy
- Using a remote backend (GCS) to manage Terraform state files for consistency and collaboration
- use terraform cloud to do the state locking or gcp datastore

# GCP Concepts and Networking

## Custom VPC
The **gcp_sandbox-prod-vpc** is the private network where everything lives, isolated from the public internet.

Inside the VPC, we create **private subnets** for each service:

### Private Subnets
- **CloudSQL Subnet**: This is where the CloudSQL database is located. It's configured for high availability (HA) with failover, so the database stays online even in case of failures.

- **Redis Subnet**: The Redis instance resides here, set up for replication. If one Redis node fails, another takes over, ensuring minimal downtime.

- **GKE Subnet**: This subnet hosts the GKE (Google Kubernetes Engine) cluster, where your containerized applications run. All GKE nodes are isolated within the VPC to prevent exposure to the public internet.

## Firewall Rules
We implement strict **firewall rules** to control traffic:
- GKE nodes are allowed to securely communicate with CloudSQL and Redis, but no external access is permitted.
- Public access to CloudSQL and Redis is blocked, and all communication happens internally within the VPC for enhanced security.

## Load Balancer
We use a application load balancer with https rule attached to it so the traffic can come through into the vpc to GKE nodes

## VPC Peering (Optional)
If you need secure communication between multiple VPCs, we can set up **VPC Peering** to ensure safe connections.

## High Availability for CloudSQL
- **CloudSQL High Availability (HA)**:
  - For **CloudSQL**, we set it up with high availability. This meanswe have a **primary instance** and a **standby replica** in a different availability zone.
  - If the primary instance fails for any reason, CloudSQL automatically switches over to the standby replica, keeping everything running smoothly with minimal downtime.

## High Availability for Redis
- **Redis Replication**:
  - For **Redis**, we set up **replication**. The master Redis node will replicate data to a **replica node**, which can take over if the master node fails.
  - This ensures that Redis stays available and data isn’t lost if something goes wrong with the master node.

## High Availability for GKE
- **GKE Cluster Autoscaling**:
  - We enable **autoscaling** in the **GKE cluster**, so it can scale up or down based on the demand. This means our apps will have enough resources when traffic is high, and they won’t waste resources when traffic is low.
  - **Multi-Zone GKE Setup**: We spread the GKE nodes across multiple availability zones. So, if one zone goes down, the other zones can keep running our apps without any interruption.


