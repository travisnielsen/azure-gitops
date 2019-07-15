# GitOps for Azure Infrastructure Lifecycle Automation

This repository describes a proposed workflow for providing automated, self-service deployment of Azure services using first party tools such as Azure DevOps and PowerShell as well as open source test libraries. This workflow is similar to what is commonly referred to as "GitOps". It is intended to illustrate how automation and commonly used collaboration tools such as git can be combined to provide rapid delivery of cloud infrastructure while complying to enterprise security standards.

## Workflow summary

Each subscription is associated with a fork from an enterprise-wide master repoistory. Subscription users create feature branches of this fork, customize ARM templates based on a library of samples, and submit infrastructure changes by creating Pull Requests (PRs) to the subscription master branch. In Azure Repos, the master branch is protected via a [Branch Policy](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops) that gathers data from the user and initiates the process, which is currently broken out into two stages.

### Pre-deployment testing and PR approval

The Build Pipeline uses a testing framework to dynamically select and execute tests that are appropriate for the contents of the ARM templates included in the PR. The PR reviewer looks at the test results and communicates with the submitter if there are any questions or concerns. If the build pipleline conditions are met and the PR reviewer approves, the request is merged into the master branch and process moves to the next stage for release.

### Release and post-deployment configuration

The Release pipeline is triggered when the PR is approved and the new content is merged into the master branch. It starts with a review and approval from a release manager. Once approved, the pipeline takes the output from the latest build and deploys or updates the infrastructure. Post-deployment configuration and validation scripts are then run to ensure the configuraiton meets pre-defined standards.
