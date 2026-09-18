# Terraform infrastructure

Run `terraform init`, `terraform validate`, and `terraform plan -refresh=false` in either `envs/dev` or `envs/prod`. The environment modules model Internet -> ALB -> ECS/Fargate in private subnets -> private RDS PostgreSQL.
