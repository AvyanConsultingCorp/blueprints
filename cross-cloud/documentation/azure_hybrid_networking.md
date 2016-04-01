<properties
   pageTitle="Cross Cloud Hybrid Networking using Azure and AWS"
   description="How to create a sample environment that demonstrates connectivity between environments that are deployed on Azure and AWS"
   services="service-name"
   documentationCenter="dev-center-name"
   authors="GitHub-alias-of-only-one-author"
   manager="manager-alias"
   editor=""/>

<tags
   ms.service="required"
   ms.devlang="may be required"
   ms.topic="article"
   ms.tgt_pltfrm="may be required"
   ms.workload="required"
   ms.date="mm/dd/yyyy"
   ms.author="Your MSFT alias or your full email address;semicolon separates two or more"/>

# Cross Cloud Networking using Microsoft Azure and Amazon Clouds

## Introduction

Sooner or later, some types of cloud solution are going to need to become cross-cloud.  What does it mean to be cross-cloud?  It's pretty straight forward, an application is cross-cloud if some portion of the solution resides on multiple clouds (public, private or both) and these clouds are connected via a network that provides communication between subsystems in different clouds.  

The cross-cloud pattern can be driven by many different business needs including:

Availability:  the business has decided that it doesn't want to take a dependency on a single cloud provider,  but instead want to spread a solution across multiple clouds and use load-balancing

Capability:  Some services/capabilities may be available in one cloud and not in another - if the business  wants to take a best-of-breed approach to the solution while realizing the advantages inherent to a cloud based solution, it could be necessary to span multiple clouds.  This pattern commonly appears in solutions that are hybrid solutions: spanning the business's private cloud and a public cloud provider.

TODO: what others?

Migration:  the application was "born" in one cloud, but in order to meet the needs of the business decides to migrate to another cloud providers.  Cross-cloud architectures can support migration of solutions that require continuous uptime and near zero-data loss while enabling the dev team to migrate in a staged, incremental manner with the ability to roll-back.  This flexibility enables teams to learn about new cloud environments while mitigating operational and business risks.  

In the remainder of this article, we'll concentrate on the migration scenario and walk the reader through a complete sample that shows how to send up two environments, one in AWS and another in Azure using Openswan VPN gateways to connect the two cloud deployments.  The workload for this scenario is Postgres replication - we'll be replicating a master database located in the virtual private cloud hosted in AWS to  a slave instance of Postgres located in an azure resource group using log shipping.

Keep in mind that this environment could support a number of different workloads:  caches, web services, machine learning clusters, etc. by simply changing the types of services and servers deployed within the cloud deployments.  The important parts to understand are principally  the network and security architecture patterns introduced here as well as the limitations of this approach which will be discussed at length after showing how the solution can be deployed.

#The Migration Scenario


## VPN Scenario - Setting up the Environment
###  Azure Side
####    Compute
####    Storage -> Trivial
#### Network -> the nasty bits
#### Application -> Postgres Install
### AWS Side
#### Compute
##### Finding AWS AMI IDs
Amazon AWS AMIs (Amazon Machine Images) have different IDs in each region.  This ID is needed in the CloudFormation template for the region that you are deploying into. Specifically, it is the "ImageId" in the Properties for the "AWS::EC2::Instance" resources. Even if the image is the same, the AMI IDs will be different in each region.  In order to implement this in the CloudFormation template, a Mapping was used to map the region name to an AMI ID. The list of AMI IDs for Ubuntu images for each region was built using Canonical's Amazon EC2 AMI Locator, http://cloud-images.ubuntu.com/locator/ec2/. Using the site, we filtered on: 
  * Version:  14.04 LTS
  * Arch:  amd64
  * Instance Type: hvm:ebs-ssd
  
and then copied / pasted the "Zone" and "AMI-ID" to the RegionMap mapping in the CloudFormation template. For more information on using CloudFormation Mappings, see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/gettingstarted.templatebasics.html. 
 
#### Storage -> Trivial
#### Network -> the nasty bits
#### Application -> Postgres Install
### Environment validation
## Findings
### Performance variations by VM type
### Network performance
### Postgres SQL Performance
## Summary and Conclusions
## Appendix
## References
## Code Listing
