# Terraform Example
The following will build out:

* TLS Private Key for EC2
* AWS Virtual Private Cloud (VPC)
* AWS Elastic File System (EFS)
* AWS ElastiCache Cluster (Redis)
* AWS Relational Database Service (RDS)
* AWS Application Load Balancer (ALB) with Listener and Target Group
* AWS Auto-Scaling Group (ASG)
* Multiple Security Groups

## Remote State
A block of the remote state is included in the [main.tf](main.tf:#L26) file as a comment/example. If you would like to use remote state, you will need to run `terraform apply` to the [remote state](../../remote-state) folder prior, plug in the values [here](main.tf#L26) and remove the surrounding comments (`#`).

## Variables
At a minimum you will need to provide the following variables (customize as needed):
```text
application               = "MyCoolApp"
rds_allocated_storage     = "20"
rds_max_allocated_storage = "100"
region                    = "us-east-2"
```

**NOTE**: Please review the `variables.tf` file included for any further customization needed.
