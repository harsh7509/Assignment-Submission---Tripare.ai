variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "task_cpu" { type = number }
variable "task_memory" { type = number }
variable "desired_count" { type = number }
variable "log_retention_days" { type = number }
variable "aws_region" { type = string }
variable "tags" {
	type    = map(string)
	default = {}
}
