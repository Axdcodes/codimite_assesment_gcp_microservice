
# CODIMITE DEVOPS ASSESMENT

 - Name: Aabidh Wadood



# Terraform & Infrastructure-as-Code (IaC)

- find the terraform files inside the ../../iac folder

- Network IAC is inside network.tf and GKE IAC is inside cluster.tf

- I've Created a github actions workflow to automate the terraform actions on ./.github/workflows/tf-actions.yml

- run terraform validation upon PR is created for correctness of changes and configurations

- in above workflow file we'll be initializing the tf backend and validate tf state and plan and upon user approval we'll deploy

- Using a remote backend (GCS) to manage Terraform state files for consistency and collaboration

- use terraform cloud to do the state locking or gcp datastore



# GCP Concepts and Networking

> refer to the architecture diagram on ../gcp-architecture.png



## Custom VPC

The **gcp_sandbox-prod-vpc** is the private network where everything lives, isolated from the public internet.



Inside the VPC, we create **private subnets** for each service:



### Private Subnets

-  **CloudSQL Subnet**: This is where the CloudSQL database is located. It's configured for high availability (HA) with failover, so the database stays online even in case of failures.



-  **Redis Subnet**: The Redis instance resides here, set up for replication. If one Redis node fails, another takes over, ensuring minimal downtime.



-  **GKE Subnet**: This subnet hosts the GKE (Google Kubernetes Engine) cluster, where your containerized applications run. All GKE nodes are isolated within the VPC to prevent exposure to the public internet.



## Firewall Rules

We implement strict **firewall rules** to control traffic:

- GKE nodes are allowed to securely communicate with CloudSQL and Redis, but no external access is permitted.

- Public access to CloudSQL and Redis is blocked, and all communication happens internally within the VPC for enhanced security.



## Load Balancer

We use a application load balancer with https rule attached to it so the traffic can come through into the vpc to GKE nodes



## VPC Peering (Optional)

If you need secure communication between multiple VPCs, we can set up **VPC Peering** to ensure safe connections.



## High Availability for CloudSQL

-  **CloudSQL High Availability (HA)**:

- For **CloudSQL**, we set it up with high availability. This meanswe have a **primary instance** and a **standby replica** in a different availability zone.

- If the primary instance fails for any reason, CloudSQL automatically switches over to the standby replica, keeping everything running smoothly with minimal downtime.



## High Availability for Redis

-  **Redis Replication**:

- For **Redis**, we set up **replication**. The master Redis node will replicate data to a **replica node**, which can take over if the master node fails.

- This ensures that Redis stays available and data isn’t lost if something goes wrong with the master node.



## High Availability for GKE

-  **GKE Cluster Autoscaling**:

- We enable **autoscaling** in the **GKE cluster**, so it can scale up or down based on the demand. This means our apps will have enough resources when traffic is high, and they won’t waste resources when traffic is low.

-  **Multi-Zone GKE Setup**: We spread the GKE nodes across multiple availability zones. So, if one zone goes down, the other zones can keep running our apps without any interruption.



# CI/CD & github Actions

I've Created a github actions workflow to automate the terraform actions on ./.github/workflows/ci-cd.yml



So, this workflow automates the whole process of building and deploying our microservice to Google Kubernetes Engine (GKE) using github Actions, Docker, GCP, and ArgoCD.



## 1. Lint and Test Job:

> so we know that the application is well structured and tested natively before building docker image

-  **Checkout Code**: The first thing it does is pull the latest code from our github repository.

-  **Set up Node.js**: If our app is built using Node.js, it sets up the right version of Node.js.

-  **Install Dependencies**: Then, it installs all the dependencies our app needs (assuming we're using npm).

-  **Run Linter**: Next, it runs a linter to check our code for any style issues.

-  **Run Tests**: Finally, it runs tests to make sure our code is working as expected.



## 2. Build Job:

-  **Checkout Code Again**: It pulls the latest code again to make sure it's up-to-date.

-  **Set up Docker Buildx**: It prepares Docker to build our image with extra features like multi-platform support.

-  **Log in to GCP**: This step logs into GCP using a service account key that's stored in github Secrets. This gives it access to GCR and GKE.

-  **Configure Docker for GCP**: It tells Docker to use GCP credentials to push images to Google Container Registry (GCR).

-  **Build and Push Docker Image**: It builds the Docker image from our code and pushes it to GCR, tagging the image with the commit hash so we know which version is being deployed.



## 3. Deploy Job:

-  **Checkout Code Again**: It pulls the latest code one more time.

-  **Set up GCP SDK**: It installs the GCP SDK, which is used to interact with GKE.

-  **Configure `kubectl`**: It sets up `kubectl` to connect to our GKE cluster using our project’s credentials. its inbuilt in GCloud CLI

-  **Set up ArgoCD CLI**: It installs the ArgoCD command-line tool, which helps manage apps in GKE.

-  **Log in to ArgoCD**: It logs into ArgoCD using the credentials we’ve stored in github Secrets.

-  **Sync Application with ArgoCD**: Finally, it tells ArgoCD to sync our application with the latest code, deploying it to GKE. The `--prune` flag removes any unnecessary resources while checking the resources in the repo itself.



## Note:

-  **Secrets**: All the sensitive info like our GCP credentials and ArgoCD credentials need to be stored securely in github Secrets.

-  **Vars**: we keep no sensitive info as vars in github actions variables

-  **ArgoCD**: Make sure ArgoCD is set up and running properly on our end. The app name in ArgoCD (`my-microservice`) needs to match what's in our configuration.



This whole setup automates our build and deployment process. So every time we push code, it runs tests natively, builds the Docker image, and deploys it to GKE using ArgoCD.




# Security & Automation Guardrails



Ive configured Trivy image scan inside the ./.github/workflows/ci-cd.yml where its necessary

- it will scan for image vulnerabilities using trivy and log the findings in the workflow




## Conftest Policy Sample


This `Conftest` policy ensures that:



1. Ensures our backend GCS bucket have encryption enabled.

2. The project is restricted to a specific allowed project.



```rego

package terraform.gcs



# Check if GCS bucket is encrypted

deny["GCS bucket not encrypted"] {

resource := input.resource_changes[_]

resource.type == "google_storage_bucket"

encryption := resource.change.after.encryption

encryption == null

}



# Ensure the project is restricted

deny["Project not restricted"] {

resource := input.resource_changes[_]

resource.type == "google_project"

project := resource.change.after

project.name != "restricted-project-name"

}

```



# Problem-Solving & Troubleshooting Scenario



## Approach



When the critical service fails, and the logs show a network timeout between the pods and CloudSQL, I’d follow these steps:



### a. Check the Logs:

- Look at the logs from the application pods and CloudSQL. Timeout means a connection issue. Check for any error messages and see when it started.



### b. Check the Network Setup:

- Check the network settings in GKE. Sometimes, policies or rules block communication between the pods and CloudSQL.

- Try `ping` or `telnet` commands to see if the pods can reach CloudSQL.



### c. CloudSQL Settings:

- Make sure CloudSQL is set to accept connections from the GKE cluster. Ensure it's online and accessible.



### d. Check Permissions:

- The GKE service account needs the right permissions (like `cloudsql.client`) to access CloudSQL.



### e. Resource Check:

- Check if the pods have enough resources (CPU, memory). If not, they might not connect properly.






## Solution



### a. Fix Network Connection:

- If network rules are wrong, I’ll fix them to allow pods to connect to CloudSQL.

- If DNS is the issue, I’ll fix those settings.



### b. Fix CloudSQL Settings:

- If CloudSQL isn’t accepting connections, I’ll update it to allow traffic from GKE or use the **CloudSQL Proxy** for more security.



### c. Fix Permissions:

- If the service account doesn’t have the proper permissions, I’ll assign `cloudsql.client` role.



### d. Test Again:

- Once the changes are done, I’ll test the connection between the pods and CloudSQL.



---



## 3. How to Prevent Future Issues:



### a. Set Up Monitoring:

- I’ll use **Google Cloud Monitoring** to track CloudSQL and GKE and configure alerts using metric-threshold/absence alerting policy in GCP observability . That way, if there’s another issue, I’ll get an alert.



### b. Use Network Policies:

- I’ll set **Kubernetes NetworkPolicies** to control which pods can talk to each other using ingress and egress or setting ploicy directly. It helps secure the network.



### c. Resource Optimization:

- I’ll set **resource requests and limits** for the pods to ensure they always have enough resources. and use **autoscaling**.



---



## Conclusion:



By checking logs, network settings, and permissions, and fixing the problem, I’ll ensure it’s working again. I’ll also set up monitoring and best practices to prevent it from happening in the future.
