# Terraform Module Examples

Most of the modules have tie ins between each other as they are commonly deployed together as part of a web application. I'll work on breaking them out further over time.

* `autorecovery_amazon_linux_2_encrypted` - Sets up an EC2 Instance using Amazon Linux 2, Encryption and auto-recovery
* `autoscale_amazon_linux_2_encrypted` - Sets up a launch template, auto-scaling group and necessary permissions / alarms. You may wish to customize the instance policy to tighten down to specific S3 buckets and repos. My original code was scoped to the clients account and for the general example here I used `resources = ["*"]`.
* `base_network` - Builds out a base VPC
* `efs` - Builds EFS to be associated with the instances in the `autoscale_amazon_linux_2_encrypted` module.
* `rds` - Primarily configured for MySQL-based RDS Instances.
* `redis` - Builds an `aws_elasticache_replication_group` for Redis.
* `remote-state` - Can be used to build out the remote-state bucket for the environment. **NOTE**: This only needs to be ran once before running the bulk of the modules. Make sure to input the appropriate values into your terraform state block.

## Examples
An example for building out several resources can be found [here](examples/vpc-efs-rds-autoscaling-elasticache/)
