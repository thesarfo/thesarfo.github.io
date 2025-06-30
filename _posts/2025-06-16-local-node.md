---
layout: post
title: "I Connected An Old Linux PC to AWS ECS"
categories:
  - aws
tags:
  - aws
comments: true
---


I recently turned a regular Linux pc sitting in my room into a fully integrated part of my AWS infrastructure, running containers orchestrated by ECS, accessing cloud-native services via VPN, and managed entirely through Systems Manager.

No EC2. No Fargate. Just one old server, some Docker, and ECS Anywhere.

This started as a weekend experiment. But I can see it becoming a core part of my setup, and honestly, it’s been eye-opening how deeply AWS services can extendd into physical hardware you already own.

Here’s how I approached it, what the architecture looks like, and some of the things I ran into.

### Why I did this

I’ve always loved the cloud for its flexibility and developer ergonomics. But for a lot of side projects and experiments, the cloud’s pay-as-you-go model ends up more like pay-for-what-you-forgot-to-turn-off.

At the same time, I’ve got a decent Linux machine at home, quiet, reliable and way underutilized. I wanted to put it to use, but not in isolation. I wanted it to feel *connected* to the cloud. Not just in terms of access, but also control and observability.

I did a bit of reading and came across ECS Anywhere.

It promised exactly what I was looking for: a way to run containers locally, while using AWS as the control plane. IAM roles, logs, container scheduling—all managed in the cloud. Compute happens on my terms.

### The Setup

The architecture I ended up with is what I’d call **hybrid edge-cloud orchestration**.

At the bottom of it is a **Docker-based ECS Anywhere instance** which is pretty much a local server registered into an ECS cluster using Systems Manager. But that’s just the beginning.

To get full access to AWS services (like RDS, S3 endpoints, or even a private Elasticache cluster), I established a **Site-to-Site VPN** from my home network to a VPC in AWS. This tunnel is what ties everything together.

Now, containers running on my pc can:

* Pull secrets from AWS Secrets Manager.
* Query private IPs in the VPC.
* Write logs to CloudWatch.
* Get IAM credentials scoped per task (yes, it works even outside EC2).

I made a few interesting decisions also

1. **I didn’t expose any ports publicly.**
   Instead of forwarding traffic directly to my home IP, I’m routing all ingress traffic through an AWS Load Balancer in the VPC, and then tunneling it back home. This lets me use Route 53, SSL termination, WAFs etc while my server sits safely behind NAT.

2. **I treat my local server as just another ECS instance.**
   Every container task is managed via ECS, nothing is “docker run”-ed manually anymore. I write task definitions, push to ECR, deploy via ECS CLI or console. It’s the cloud experience, minus the compute bill.

3. **IAM works surprisingly well.**
   Since the ECS agent piggybacks on Systems Manager, AWS can assume control and inject temporary credentials just like it would with EC2 metadata. The ECS task IAM roles apply cleanly, even for local containers.


A few things also caught me off guard

* **CloudWatch Agent on local servers is a must.**
  ECS won’t auto-ship logs like it does with Fargate or EC2, so I had to configure Fluent Bit or the CloudWatch agent myself.

* **VPN config wasn’t plug-and-play.**
  The IPSec configuration AWS gives you works—but only if your router and OS don’t get in the way. I had to fight with MTU sizes, NAT traversal, and `strongSwan` config quirks to get stable traffic.

* **Networking gets messy fast.**
  Once your containers start talking to the cloud and each other across that tunnel, things like DNS resolution and routing tables become serious concerns. I ended up using split-horizon DNS with Route 53 private zones.


### Why This Has Changed the Way I Think About Hybrid Infrastructure

What surprised me most about this setup isn’t just that it works, it’s *how seamlessly it integrates with AWS-native services*. To AWS, my home machine is just another node. I can schedule a Redis container locally, connect it to a managed RDS instance, and monitor it all from the AWS Console without needing to SSH or expose a single port.

This is part of a home lab I'm setting up so it'll definitely become part of my actual dev ecosystem. I'm feeling lazy to draw a diagram of how the architecture looks like, maybe I'll update this when I finally do.

And the best part? I can scale it. If I add another pc can register it too. ECS will manage both, just like it would any EC2 cluster. I can spread workloads across my own mini datacenter, and let AWS orchestrate it all.


I’m now experimenting with:

* **GitOps-style deployments** from a CodePipeline into my home lab.
* **Local inference workloads** (LLMs, OCR, etc.) that report metrics back to the cloud.
* **Prometheus + Grafana** on-prem but visualized alongside AWS CloudWatch.
* A way to spin up containers remotely via SSM commands without exposing SSH.

And yes, I’m also preparing for when my power goes out, so UPS and smart failover are on the list too.


### Final Thoughts

If you’ve got unused hardware and some curiosity, ECS Anywhere is one of the most underappreciated tools in AWS right now. It’s not about saving money (though you might). It’s about building *infrastructure* that lives both in your rack and in the cloud.

You own the metal. AWS owns the control plane. And together, they do something kind of beautiful
