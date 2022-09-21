# Common Components
This folder contains GCP project setup scripts using Terraform, a generic container orchestration capability leveraging Cloud Composer,
and performance monitoring tools.

This folder may be enhanced in the future with additional common components that can provide core functionalities
required by any regulatory report.

To initialise the common components do the following:

## Common Setup

* Run the gcloud init command, and ensure that a default project and default compute zone is defined.
    ```
    gcloud init
    ```

* Execute the `setup_script.sh`. This will create a `backend.tf` and `terraform.tfvars` files based on the templates.

    ```
    . ./setup_script.sh
    ```

* If you wish to create a composer infrastructure, make sure that the `terraform.tfvars` has the `enable_composer=true`  


## Infrastructure creation

Once the `backend.tf` and `terraform.tfvars` are updated, create the infrastructure by executing:
```
terraform init
terraform plan
terraform apply
```
