# The Pins Team's Code Server deplpyment repo

This repository containing the toolkit and Dockerfile for running
your own Code Server on the container-based PaaS services.

## code-server on a VM vs. a Container

- VMs are deployed once, and then can be modified to install new software
  - You need to save "snapshots" to use your latest images
  - Storage is always persistent, and you can usually add extra volumes
  - VMs can support many workloads, such as running Docker or Kubernetes clusters
  - [👀 Docs for the VM install script](deploy-vm/)
- Deployed containers do not persist, and are often rebuilt
  - Containers can shut down when you are not using them, saving you money
  - All software and dependencies need to be defined in the `Dockerfile` or install script so they aren't destroyed on a rebuild. This is great if you want to have a new, clean environment every time you code
  - Storage may not be redundant. You may have to use [rclone](https://rclone.org/) to store your filesystem on a cloud service, for info:
  - [📄 Docs for code-server-deploy-container](deploy-container/)

## Add more dependencies?

_(especially new extensions?)_

* If it's just for you, please fork the repo and edit `Dockerfile`.
* For repo collaborators, you can either do editing the `Dockerfile`
(which may break the CI builds) or send an PR.
