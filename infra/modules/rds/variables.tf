variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage" { type = number }
variable "backup_retention_period" { type = number }
variable "deletion_protection" { type = bool }
variable "skip_final_snapshot" { type = bool }
variable "multi_az" { type = bool }
variable "db_name" { type = string }
variable "username" { type = string }
variable "engine_version" { type = string }
variable "tags" { type = map(string) default = {} }
