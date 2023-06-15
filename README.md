# minecraft-aws

A Terraform/Helm configuration and Bash scripts to quickly deploy a Minecraft server in AWS's Elastic Kubernetes Service.

Adapted from [Hashicorp's EKS Tutorial](https://github.com/hashicorp/learn-terraform-provision-eks-cluster) and utilized [Geoff Bourne's Helm chart](https://artifacthub.io/packages/helm/minecraft-server-charts/minecraft). Thank you both!

## Background

What The Company needs is a grossly-overengineered solution to the problem of system administrators' work not being reproducible. To this end, we will deploy a Minecraft server in the cloud, where it will be always accessible, and on Kubernetes where it can adapt to the load that users place on it. (But ignore the part where Minecraft was never engineered to be horizontally scalable and that we can't have more than 1 replica on the cluster in practice...)

We will also implement persistent storage for the cluster, so that restarts or shutdowns of the cluster to do not result in a loss of Minecraft world data. Employees would be heartbroken if their hard work in Minecraft was lost, and they were forced to return to their jobs.

## Pipeline

```

     Operating Computer
          (you!)
            |
            |
            |
            - - > Terraform - - - - - > AWS
            |                            1. Creates VPC networking
            |                            2. Creates EKS cluster
            |                            3. Creates related EC2 utilities
            |                               (Instances, Security Groups, etc)
            |
            |
            |
            - - > Helm / Kubectl - - - > AWS
            |                             1. Deployes Minecraft server Chart onto the cluster
            |                             2. Configures the Load Balancer to provide external access to the cluster
            |
        Cluster IP
            
            
        End Users - - > Minecraft - - - > AWS Cluster - - - > Minecraft Server
        
```

## Requirements

### Linux

These tools are primarily built for Linux distributions. You will need to choose your favorite Linux distro and install it on the computer of your choice before proceeding.

You may find [this tutorial](https://wiki.archlinux.org/title/installation_guide) helpful.

### AWS

To run these scripts, you will need an AWS account with EKS and Role permissions to set up. For ease of use, you can run this as your root AWS account, but **this is NOT recommended** for security reasons.

You will also need to generate and save your AWS access details for this account. you can do this from the drop down menu in the top right corner of the AWS console, and click "Security credentials." Under the "Access keys" section, click "Create access key" and copy both your "Access key" and your "Secret access key" and paste it somewhere for safe keeping. You will enter it in a configuration file shortly.

Next, we will want to create the `~/.aws` directory: `$ mkdir ~/.aws`. And create two files: `$ touch ~/.aws/credentials ~/.aws/config`. The format of these files will look like the following, with content in angle brackets replaced with the relevant info:

`~/.aws/credentials`
```ini
[default]
aws_access_key_id=<YOUR ACCESS KEY HERE>
aws_secret_access_key=<YOUR SECRET ACCESS KEY HERE>
```

`~/.aws/config`
```ini
[default]
region=<YOUR PREFERRED REGION CODE HERE>
```

An example region could be `us-west-2`.

### Tools

The following tools will need to be installed:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Helm](https://helm.sh/docs/intro/install/#from-script)

Several of these are installable from distro package managers, but not all of them. When in doubt, install from the official provider's website shown.

## Deployment Guide

Included is a Bash script labeled `setup.sh`. Run the following commands after the previous requirements have been satisfied with:

```sh
$ chmod 700 ./setup.sh
$ ./setup.sh
```

This will begin the process of provisioning and configuring the Kubernetes cluster on AWS. Be patient! It will likely take 30 minutes to an hour to complete.

The very last thing that the script will do is output the access point of the server. This link is what you will provide to the end users to connect to the Minecraft server.

### Storage Persistence

The cluster is configured through Terraform to use the [Container Storage Interface (CSI)](https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/) on AWS, which stores it on EBS. There is also an option to configure in the Minecraft Helm Chart to specify that persistent storage should be used. With these two configurations, the world data of the Minecraft cluster is stored on EBS, so that in the case of a cluster shutdown or restart, it will not be lost.

The EBS volume storing the world data can be identified in the EBS dashboard by referencing the cluster name, such as `the-minecraft-cluster-dynamic-pvc-48d58ee0-9b70-41e8-b305-86d0f2476708`. It should be 1 GiB in size.

### Tearing Down the cluster

An additional script is included in the repository to tear down the cluster on AWS. It will first uninstall the Helm Chart from the cluster, and then begin deleting the resources that Terraform created for the cluster.

**Be sure to backup your minecraft world before running the destroy script!** The teardown process will also delete the EBS storage associated with the cluster, containing the Minecraft world data.

## Connecting to the Server as a User

Upon opening Minecraft, click on "Multiplayer" and then "Direct Connection." Input the Server Address given by the system administrator and click "Join Server." You should connect momentarily.

### Debugging Option

If unable to connect to the Minecraft server for any reason, install nmap and try this command:

```sh
$ nmap -sV -Pn -p T:25565 <server address>
```
