# Infrastructure Setup with Terraform

This repository contains Terraform code to set up infrastructure on Google Cloud Platform (GCP).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- Google Cloud Platform account.
- Google Cloud SDK (gcloud) installed and authenticated.

## Setup

1. Clone this repository:

    ```bash
    git clone git@github.com:thejusthomson-csy6225/tf-gcp-infra.git
    cd tf-gcp-infra
    ```

2. Create a `terraform.tfvars` file with the required variables:

    ```hcl
    vpc_count = 2
    ```

3. Initialize and apply the Terraform configuration:

    ```bash
    terraform init
    terraform apply
    ```

    This will prompt you to confirm the changes. Type `yes` to proceed.

4. Once the infrastructure is set up, you can access the Google Cloud Console to view the created resources.

## Cleanup

To destroy the infrastructure when no longer needed:

```bash
terraform destroy
